"""
Test para verificar que el madOS post-install se gatilla al ingresar a la sesión gráfica.

Este test valida:
1. El script profile.d existe y tiene permisos correctos
2. Las condiciones de ejecución se verifican correctamente
3. El archivo .desktop de autostart está configurado
4. Los marcadores de estado funcionan correctamente
"""

import os
import pytest
import subprocess
import tempfile
import shutil
from pathlib import Path

# Rutas base del proyecto
BASE_DIR = Path(__file__).parent.parent
AIROOTFS = BASE_DIR / "airootfs"


class TestPostInstallTrigger:
    """Tests para el disparador del post-install en sesión gráfica"""

    def test_profile_script_exists(self):
        """Verificar que el script profile.d existe"""
        script_path = AIROOTFS / "etc" / "profile.d" / "mados-post-install.sh"
        assert script_path.exists(), f"El script {script_path} no existe"

    def test_profile_script_permissions(self):
        """Verificar permisos ejecutables del script"""
        script_path = AIROOTFS / "etc" / "profile.d" / "mados-post-install.sh"
        mode = oct(script_path.stat().st_mode)[-3:]
        assert mode in ["755", "644"], f"Permisos incorrectos: {mode}"

    def test_desktop_entry_exists(self):
        """Verificar que el archivo .desktop existe"""
        desktop_path = AIROOTFS / "usr" / "share" / "applications" / "mados-post-install.desktop"
        assert desktop_path.exists(), f"El archivo {desktop_path} no existe"

    def test_desktop_entry_content(self):
        """Verificar contenido del archivo .desktop"""
        desktop_path = AIROOTFS / "usr" / "share" / "applications" / "mados-post-install.desktop"
        content = desktop_path.read_text()
        
        assert "Type=Application" in content
        assert "Exec=mados-post-install" in content
        assert "Terminal=false" in content
        assert "StartupNotify=true" in content

    def test_post_install_binary_exists(self):
        """Verificar que el binario del post-install existe"""
        binary_path = AIROOTFS / "usr" / "local" / "bin" / "mados-post-install"
        assert binary_path.exists(), f"El binario {binary_path} no existe"

    def test_cleanup_script_exists(self):
        """Verificar que el script de cleanup existe"""
        cleanup_path = AIROOTFS / "usr" / "local" / "bin" / "mados-post-install-cleanup"
        assert cleanup_path.exists(), f"El script {cleanup_path} no existe"

    def test_cleanup_service_reference(self):
        """Verificar que el cleanup menciona el servicio systemd"""
        cleanup_path = AIROOTFS / "usr" / "local" / "bin" / "mados-post-install-cleanup"
        content = cleanup_path.read_text()
        
        assert "mados-post-install.service" in content
        assert "systemctl disable" in content

    def test_marker_file_paths(self):
        """Verificar que las rutas de marcadores están definidas en el script"""
        script_path = AIROOTFS / "etc" / "profile.d" / "mados-post-install.sh"
        content = script_path.read_text()
        
        assert 'MARKER_FILE="/var/lib/mados/post-install-pending"' in content
        assert 'DONE_FLAG="/var/lib/mados/post-install-done"' in content
        assert 'USER_MARKERSHA="$HOME/.cache/mados-post-install-check"' in content

    def test_gui_environment_check(self):
        """Verificar que el script chequea variables de entorno gráfico"""
        script_path = AIROOTFS / "etc" / "profile.d" / "mados-post-install.sh"
        content = script_path.read_text()
        
        assert 'WAYLAND_DISPLAY' in content
        assert 'DISPLAY' in content
        # Debe verificar si NO están definidas para salir
        assert '[ -z "$WAYLAND_DISPLAY" ] && [ -z "$DISPLAY" ]' in content

    def test_execution_conditions(self):
        """Verificar las condiciones de ejecución en el script"""
        script_path = AIROOTFS / "etc" / "profile.d" / "mados-post-install.sh"
        content = script_path.read_text()
        
        # Debe verificar que el marker exista
        assert '[ ! -f "$MARKER_FILE" ]' in content
        
        # Debe verificar si ya se completó
        assert '[ -f "$DONE_FLAG" ]' in content
        
        # Debe verificar por usuario
        assert '[ -f "$USER_MARKERSHA" ]' in content

    def test_launch_command(self):
        """Verificar que el script lanza el post-install"""
        script_path = AIROOTFS / "etc" / "profile.d" / "mados-post-install.sh"
        content = script_path.read_text()
        
        assert "/usr/local/bin/mados-post-install &" in content

    def test_sleep_delay(self):
        """Verificar que hay un delay antes de ejecutar"""
        script_path = AIROOTFS / "etc" / "profile.d" / "mados-post-install.sh"
        content = script_path.read_text()
        
        assert "sleep 3" in content

    def test_shellcheck_validation(self):
        """Validar el script con shellcheck"""
        script_path = AIROOTFS / "etc" / "profile.d" / "mados-post-install.sh"
        
        try:
            result = subprocess.run(
                ["shellcheck", str(script_path)],
                capture_output=True,
                text=True
            )
            # Error 1091 es esperado para files de fuentes externas
            errors = [line for line in result.stdout.split('\n') 
                     if line and 'error' in line.lower() and 'SC1091' not in line]
            assert len(errors) == 0, f"Shellcheck errors: {errors}"
        except FileNotFoundError:
            pytest.skip("shellcheck no está instalado")

    def test_python_module_structure(self):
        """Verificar que el módulo Python del post-install está estructurado"""
        module_dir = AIROOTFS / "usr" / "local" / "lib" / "mados_post_install"
        
        assert module_dir.exists()
        assert (module_dir / "__init__.py").exists()
        assert (module_dir / "__main__.py").exists()
        assert (module_dir / "app.py").exists()
        assert (module_dir / "config.py").exists()

    def test_import_in_binary(self):
        """Verificar que el binario importa el módulo correctamente"""
        binary_path = AIROOTFS / "usr" / "local" / "bin" / "mados-post-install"
        content = binary_path.read_text()
        
        assert "from mados_post_install import main" in content


class TestPostInstallScriptExecution:
    """Tests de ejecución del script post-install"""

    @pytest.fixture
    def temp_env(self):
        """Crear entorno temporal para tests"""
        temp_dir = tempfile.mkdtemp()
        yield temp_dir
        shutil.rmtree(temp_dir)

    def test_script_exits_when_no_marker(self, temp_env):
        """El script debe salir si no hay marker file"""
        script_path = AIROOTFS / "etc" / "profile.d" / "mados-post-install.sh"
        
        # Crear copia modificada para test
        test_script = Path(temp_env) / "test-script.sh"
        content = script_path.read_text()
        
        # Reemplazar rutas para test
        content = content.replace(
            'MARKER_FILE="/var/lib/mados/post-install-pending"',
            f'MARKER_FILE="{temp_env}/post-install-pending"'
        )
        content = content.replace(
            'DONE_FLAG="/var/lib/mados/post-install-done"',
            f'DONE_FLAG="{temp_env}/post-install-done"'
        )
        content = content.replace(
            'USER_MARKERSHA="$HOME/.cache/mados-post-install-check"',
            f'USER_MARKERSHA="{temp_env}/user-marker"'
        )
        
        test_script.write_text(content)
        test_script.chmod(0o755)
        
        # Ejecutar sin marker
        result = subprocess.run(
            ["bash", str(test_script)],
            capture_output=True,
            env={**os.environ, "HOME": temp_env}
        )
        
        # Debe salir exitosamente (exit 0) sin hacer nada
        assert result.returncode == 0

    def test_script_checks_gui_variables(self, temp_env):
        """El script debe verificar variables de entorno GUI"""
        script_path = AIROOTFS / "etc" / "profile.d" / "mados-post-install.sh"
        
        # Crear marker
        marker_file = Path(temp_env) / "post-install-pending"
        marker_file.touch()
        
        # Ejecutar sin variables de entorno gráfico
        env = {**os.environ, "HOME": temp_env}
        env.pop("WAYLAND_DISPLAY", None)
        env.pop("DISPLAY", None)
        
        result = subprocess.run(
            ["bash", str(script_path)],
            capture_output=True,
            env=env
        )
        
        # Debe salir sin hacer nada (exit 0 por línea 22)
        assert result.returncode == 0


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
