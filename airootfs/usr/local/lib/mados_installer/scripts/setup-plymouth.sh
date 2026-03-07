#!/bin/bash
# madOS Plymouth Boot Splash Setup
set -e

mkdir -p /usr/share/plymouth/themes/mados

cat > /usr/share/plymouth/themes/mados/mados.plymouth <<EOFPLY
[Plymouth Theme]
Name=madOS
Description=madOS boot splash with Nord theme
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/mados
ScriptFile=/usr/share/plymouth/themes/mados/mados.script
EOFPLY

cat > /usr/share/plymouth/themes/mados/mados.script <<'EOFSCRIPT'
Window.SetBackgroundTopColor(0.18, 0.20, 0.25);
Window.SetBackgroundBottomColor(0.13, 0.15, 0.19);
logo.image = Image("logo.png");
logo.sprite = Sprite(logo.image);
logo.sprite.SetX(Window.GetWidth() / 2 - logo.image.GetWidth() / 2);
logo.sprite.SetY(Window.GetHeight() / 2 - logo.image.GetHeight() / 2 - 50);
logo.sprite.SetZ(10);
logo.sprite.SetOpacity(1);
NUM_DOTS = 8;
SPINNER_RADIUS = 25;
spinner_x = Window.GetWidth() / 2;
spinner_y = Window.GetHeight() / 2 + logo.image.GetHeight() / 2;
dot_image = Image("dot.png");
for (i = 0; i < NUM_DOTS; i++) {
    dot[i].sprite = Sprite(dot_image);
    dot[i].sprite.SetZ(10);
    angle = i * 2 * 3.14159 / NUM_DOTS;
    dot[i].sprite.SetX(spinner_x + SPINNER_RADIUS * Math.Sin(angle) - dot_image.GetWidth() / 2);
    dot[i].sprite.SetY(spinner_y - SPINNER_RADIUS * Math.Cos(angle) - dot_image.GetHeight() / 2);
    dot[i].sprite.SetOpacity(0.2);
}
frame = 0;
fun refresh_callback() {
    frame++;
    active_dot = Math.Int(frame / 4) % NUM_DOTS;
    for (i = 0; i < NUM_DOTS; i++) {
        dist = active_dot - i;
        if (dist < 0) dist = dist + NUM_DOTS;
        if (dist == 0) opacity = 1.0;
        else if (dist == 1) opacity = 0.7;
        else if (dist == 2) opacity = 0.45;
        else if (dist == 3) opacity = 0.25;
        else opacity = 0.12;
        dot[i].sprite.SetOpacity(opacity);
    }
    pulse = Math.Abs(Math.Sin(frame * 0.02)) * 0.08 + 0.92;
    logo.sprite.SetOpacity(pulse);
}
Plymouth.SetRefreshFunction(refresh_callback);
fun display_normal_callback(text) {}
fun display_message_callback(text) {}
Plymouth.SetDisplayNormalFunction(display_normal_callback);
Plymouth.SetMessageFunction(display_message_callback);
fun quit_callback() {
    for (i = 0; i < NUM_DOTS; i++) { dot[i].sprite.SetOpacity(0); }
    logo.sprite.SetOpacity(1);
}
Plymouth.SetQuitFunction(quit_callback);
EOFSCRIPT

plymouth-set-default-theme mados 2>/dev/null || true
mkdir -p /etc/plymouth

cat > /etc/plymouth/plymouthd.conf <<EOFPLYCONF
[Daemon]
Theme=mados
ShowDelay=0
DeviceTimeout=5
EOFPLYCONF

echo "  Plymouth boot splash configured"
