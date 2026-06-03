#!/usr/bin/perl
use warnings;
use strict;
use Tk;

# ONN Webcam V4L2 Settings GUI
# All controls from v4l2-ctl -L for Walmart ONN webcam
# Ubuntu 24.04

my $mw = MainWindow->new(-title => 'ONN Webcam Settings');
$mw->geometry('520x920');

my $device = '/dev/video0';

sub apply_ctrl {
    my ($ctrl, $val) = @_;
    system("v4l2-ctl -d $device --set-ctrl $ctrl=$val 2>/dev/null");
}

sub make_slider {
    my ($parent, $label, $ctrl, $min, $max, $default, $row) = @_;
    $parent->Label(-text => $label, -width => 28, -anchor => 'w')
        ->grid(-row => $row, -column => 0, -sticky => 'w', -padx => 5);
    my $val_label = $parent->Label(-text => $default, -width => 6);
    $val_label->grid(-row => $row, -column => 2, -padx => 5);
    my $scale = $parent->Scale(
        -from        => $min,
        -to          => $max,
        -orient      => 'horizontal',
        -length      => 250,
        -showvalue   => 0,
        -command     => sub {
            my $v = int($_[0]);
            $val_label->configure(-text => $v);
            apply_ctrl($ctrl, $v);
        },
    );
    $scale->set($default);
    $scale->grid(-row => $row, -column => 1, -padx => 5, -pady => 2);
    return $scale;
}

my $row = 0;

# Title
$mw->Label(-text => 'ONN Webcam V4L2 Controls', -font => 'Helvetica 14 bold')
    ->grid(-row => $row++, -column => 0, -columnspan => 3, -pady => 10);

# ---- User Controls ----
$mw->Label(-text => '--- User Controls ---', -font => 'Helvetica 11 bold')
    ->grid(-row => $row++, -column => 0, -columnspan => 3, -pady => 5);

make_slider($mw, 'Brightness',             'brightness',             -64, 64,  0,   $row++);
make_slider($mw, 'Contrast',               'contrast',               0,   95,  32,  $row++);
make_slider($mw, 'Saturation',             'saturation',             0,   120, 64,  $row++);
make_slider($mw, 'Hue',                    'hue',                    -32, 32,  0,   $row++);
make_slider($mw, 'Gain',                   'gain',                   0,   100, 0,   $row++);
make_slider($mw, 'Sharpness',              'sharpness',              0,   7,   3,   $row++);
make_slider($mw, 'Backlight Compensation', 'backlight_compensation', 0,   12,  6,   $row++);

# White Balance Auto checkbox
my $wb_auto = 1;
$mw->Checkbutton(
    -text     => 'White Balance Automatic',
    -variable => \$wb_auto,
    -command  => sub { apply_ctrl('white_balance_automatic', $wb_auto); },
)->grid(-row => $row++, -column => 0, -columnspan => 3, -pady => 3);

# White Balance Temp - only works when white_balance_automatic=0
$mw->Label(-text => 'White Balance Temp', -width => 28, -anchor => 'w')
    ->grid(-row => $row, -column => 0, -sticky => 'w', -padx => 5);
my $wbt_label = $mw->Label(-text => 4000, -width => 6);
$wbt_label->grid(-row => $row, -column => 2, -padx => 5);
my $wbt_scale = $mw->Scale(
    -from => 2800, -to => 6500, -orient => 'horizontal', -length => 250,
    -showvalue => 0,
    -command => sub {
        my $v = int($_[0]);
        $wbt_label->configure(-text => $v);
        if (!$wb_auto) {
            apply_ctrl('white_balance_temperature', $v);
        }
    },
);
$wbt_scale->set(4000);
$wbt_scale->grid(-row => $row++, -column => 1, -padx => 5, -pady => 2);

# Power Line Frequency
$mw->Label(-text => 'Power Line Frequency:', -width => 28, -anchor => 'w')
    ->grid(-row => $row, -column => 0, -sticky => 'w', -padx => 5);
my $plf = 2;
my $plf_frame = $mw->Frame->grid(-row => $row++, -column => 1, -columnspan => 2);
$plf_frame->Radiobutton(-text => 'Off', -variable => \$plf, -value => 0,
    -command => sub { apply_ctrl('power_line_frequency', $plf); })->pack(-side => 'left');
$plf_frame->Radiobutton(-text => '50Hz', -variable => \$plf, -value => 1,
    -command => sub { apply_ctrl('power_line_frequency', $plf); })->pack(-side => 'left');
$plf_frame->Radiobutton(-text => '60Hz', -variable => \$plf, -value => 2,
    -command => sub { apply_ctrl('power_line_frequency', $plf); })->pack(-side => 'left');

# ---- Camera Controls ----
$mw->Label(-text => '--- Camera Controls ---', -font => 'Helvetica 11 bold')
    ->grid(-row => $row++, -column => 0, -columnspan => 3, -pady => 5);

# Auto Exposure
$mw->Label(-text => 'Auto Exposure:', -width => 28, -anchor => 'w')
    ->grid(-row => $row, -column => 0, -sticky => 'w', -padx => 5);
my $ae = 3;
my $ae_frame = $mw->Frame->grid(-row => $row++, -column => 1, -columnspan => 2);
$ae_frame->Radiobutton(-text => 'Manual', -variable => \$ae, -value => 1,
    -command => sub { apply_ctrl('auto_exposure', $ae); })->pack(-side => 'left');
$ae_frame->Radiobutton(-text => 'Aperture Priority', -variable => \$ae, -value => 3,
    -command => sub { apply_ctrl('auto_exposure', $ae); })->pack(-side => 'left');

make_slider($mw, 'Exposure Time Absolute', 'exposure_time_absolute', 1,    5000,  157, $row++);

# Exposure Dynamic Framerate checkbox
my $edf = 0;
$mw->Checkbutton(
    -text     => 'Exposure Dynamic Framerate',
    -variable => \$edf,
    -command  => sub { apply_ctrl('exposure_dynamic_framerate', $edf); },
)->grid(-row => $row++, -column => 0, -columnspan => 3, -pady => 3);

make_slider($mw, 'Pan Absolute',           'pan_absolute',           -36000, 36000, 0,  $row++);
make_slider($mw, 'Tilt Absolute',          'tilt_absolute',          -36000, 36000, 0,  $row++);
make_slider($mw, 'Focus Absolute',         'focus_absolute',         0,      255,   50, $row++);

# Focus Auto checkbox
my $fa = 1;
$mw->Checkbutton(
    -text     => 'Focus Automatic Continuous',
    -variable => \$fa,
    -command  => sub { apply_ctrl('focus_automatic_continuous', $fa); },
)->grid(-row => $row++, -column => 0, -columnspan => 3, -pady => 3);

make_slider($mw, 'Zoom Absolute',          'zoom_absolute',          0, 9, 0, $row++);

# Privacy checkbox
my $priv = 0;
$mw->Checkbutton(
    -text     => 'Privacy',
    -variable => \$priv,
    -command  => sub { apply_ctrl('privacy', $priv); },
)->grid(-row => $row++, -column => 0, -columnspan => 3, -pady => 3);

# ---- Preset Buttons ----
$mw->Label(-text => '--- Presets ---', -font => 'Helvetica 11 bold')
    ->grid(-row => $row++, -column => 0, -columnspan => 3, -pady => 5);

my $btn_frame1 = $mw->Frame->grid(-row => $row++, -column => 0, -columnspan => 3, -pady => 5);
my $btn_frame2 = $mw->Frame->grid(-row => $row++, -column => 0, -columnspan => 3, -pady => 5);

$btn_frame1->Button(-text => 'Night', -bg => '#223', -fg => 'white', -width => 12, -command => sub {
    apply_ctrl('auto_exposure', 3);
    sleep(1);
    apply_ctrl('brightness', 64);
    apply_ctrl('contrast', 15);
    apply_ctrl('saturation', 30);
    apply_ctrl('sharpness', 7);
    apply_ctrl('gain', 100);
    apply_ctrl('backlight_compensation', 12);
    apply_ctrl('exposure_dynamic_framerate', 1);
    apply_ctrl('focus_automatic_continuous', 0);
    apply_ctrl('focus_absolute', 51);
    apply_ctrl('white_balance_automatic', 1);
    apply_ctrl('zoom_absolute', 0);
})->pack(-side => 'left', -padx => 5);

$btn_frame1->Button(-text => 'Day', -bg => '#cde', -fg => 'black', -width => 12, -command => sub {
    apply_ctrl('auto_exposure', 1);
    sleep(1);
    apply_ctrl('brightness', 0);
    apply_ctrl('contrast', 32);
    apply_ctrl('saturation', 64);
    apply_ctrl('sharpness', 5);
    apply_ctrl('gain', 20);
    apply_ctrl('backlight_compensation', 4);
    apply_ctrl('exposure_time_absolute', 80);
    apply_ctrl('exposure_dynamic_framerate', 0);
    apply_ctrl('focus_automatic_continuous', 0);
    apply_ctrl('focus_absolute', 50);
    apply_ctrl('white_balance_automatic', 1);
    apply_ctrl('zoom_absolute', 0);
})->pack(-side => 'left', -padx => 5);

$btn_frame1->Button(-text => 'Bright Sun', -bg => '#ff9', -fg => 'black', -width => 12, -command => sub {
    apply_ctrl('auto_exposure', 1);
    sleep(1);
    apply_ctrl('brightness', -30);
    apply_ctrl('contrast', 40);
    apply_ctrl('saturation', 50);
    apply_ctrl('sharpness', 7);
    apply_ctrl('gain', 0);
    apply_ctrl('backlight_compensation', 0);
    apply_ctrl('exposure_time_absolute', 2);
    apply_ctrl('exposure_dynamic_framerate', 0);
    apply_ctrl('focus_automatic_continuous', 0);
    apply_ctrl('focus_absolute', 50);
    apply_ctrl('white_balance_automatic', 0);
    apply_ctrl('white_balance_temperature', 5500);
    apply_ctrl('zoom_absolute', 0);
})->pack(-side => 'left', -padx => 5);

$btn_frame2->Button(-text => 'Cloudy Day', -bg => '#aab', -fg => 'black', -width => 12, -command => sub {
    apply_ctrl('auto_exposure', 1);
    sleep(1);
    apply_ctrl('brightness', 10);
    apply_ctrl('contrast', 35);
    apply_ctrl('saturation', 55);
    apply_ctrl('sharpness', 6);
    apply_ctrl('gain', 30);
    apply_ctrl('backlight_compensation', 5);
    apply_ctrl('exposure_time_absolute', 200);
    apply_ctrl('exposure_dynamic_framerate', 0);
    apply_ctrl('focus_automatic_continuous', 0);
    apply_ctrl('focus_absolute', 50);
    apply_ctrl('white_balance_automatic', 0);
    apply_ctrl('white_balance_temperature', 6000);
    apply_ctrl('zoom_absolute', 0);
})->pack(-side => 'left', -padx => 5);

$btn_frame2->Button(-text => 'Defaults', -width => 12, -command => sub {
    apply_ctrl('brightness', 0);
    apply_ctrl('contrast', 32);
    apply_ctrl('saturation', 64);
    apply_ctrl('hue', 0);
    apply_ctrl('gain', 0);
    apply_ctrl('sharpness', 3);
    apply_ctrl('backlight_compensation', 6);
    apply_ctrl('white_balance_automatic', 1);
    apply_ctrl('white_balance_temperature', 4000);
    apply_ctrl('power_line_frequency', 2);
    apply_ctrl('auto_exposure', 3);
    apply_ctrl('exposure_time_absolute', 157);
    apply_ctrl('exposure_dynamic_framerate', 0);
    apply_ctrl('pan_absolute', 0);
    apply_ctrl('tilt_absolute', 0);
    apply_ctrl('focus_absolute', 50);
    apply_ctrl('focus_automatic_continuous', 1);
    apply_ctrl('zoom_absolute', 0);
    apply_ctrl('privacy', 0);
})->pack(-side => 'left', -padx => 5);

MainLoop;
