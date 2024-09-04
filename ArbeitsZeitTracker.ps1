Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$global:startZeit = $null
$global:pausenZeit = [TimeSpan]::Zero
$global:pauseStartZeit = $null
$global:arbeitszeitEnde = $null
$global:istPause = $false

function Update-Anzeige {
    if ($global:startZeit -eq $null) { return }
    $aktuelleZeit = Get-Date
    $gearbeiteteZeit = $aktuelleZeit - $global:startZeit - $global:pausenZeit
    if ($global:pauseStartZeit -ne $null) {
        $gearbeiteteZeit -= ($aktuelleZeit - $global:pauseStartZeit)
    }
    $verbleibendeZeit = $global:arbeitszeitEnde - $aktuelleZeit
    if ($verbleibendeZeit.TotalSeconds -lt 0) { $verbleibendeZeit = [TimeSpan]::Zero }
    $labelArbeitszeit.Text = $gearbeiteteZeit.ToString("hh\:mm")
    $labelEnde.Text = $global:arbeitszeitEnde.ToString("HH:mm")
    $labelVerbleibend.Text = $verbleibendeZeit.ToString("hh\:mm")
    $labelPausenZeit.Text = $global:pausenZeit.ToString("hh\:mm")
}

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Arbeitszeit-Tracker'
$form.Size = New-Object System.Drawing.Size(245,440)  # Erhöhte Höhe für den neuen Button
$form.StartPosition = 'Manual'
$form.Location = New-Object System.Drawing.Point(0, 0)
$form.TopMost = $true
$form.FormBorderStyle = 'FixedSingle'
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::White

$titleFont = New-Object System.Drawing.Font("Segoe UI", 9)
$valueFont = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$buttonFont = New-Object System.Drawing.Font("Segoe UI", 9)

function Create-TimeDisplay($title, $y) {
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Location = New-Object System.Drawing.Point(10, $y)
    $titleLabel.Size = New-Object System.Drawing.Size(200, 25)
    $titleLabel.Text = $title
    $titleLabel.Font = $titleFont
    $titleLabel.ForeColor = [System.Drawing.Color]::Gray
    $form.Controls.Add($titleLabel)

    $valueLabel = New-Object System.Windows.Forms.Label
    $valueLabel.Location = New-Object System.Drawing.Point(10, ($y + 25))
    $valueLabel.Size = New-Object System.Drawing.Size(200, 30)
    $valueLabel.Text = "00:00"
    $valueLabel.Font = $valueFont
    $valueLabel.ForeColor = [System.Drawing.Color]::DarkBlue
    $form.Controls.Add($valueLabel)

    return $valueLabel
}

$labelArbeitszeit = Create-TimeDisplay 'ARBEITSZEIT' 10
$labelEnde = Create-TimeDisplay 'ENDE' 75
$labelVerbleibend = Create-TimeDisplay 'VERBLEIBEND' 140
$labelPausenZeit = Create-TimeDisplay 'PAUSENZEIT' 205

function Create-Button($text, $x, $y, $width, $height) {
    $button = New-Object System.Windows.Forms.Button
    $button.Location = New-Object System.Drawing.Point($x, $y)
    $button.Size = New-Object System.Drawing.Size($width, $height)
    $button.Text = $text
    $button.Font = $buttonFont
    $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $button.BackColor = [System.Drawing.Color]::LightGray
    $button.ForeColor = [System.Drawing.Color]::DarkBlue
    $form.Controls.Add($button)
    return $button
}

$startButton = Create-Button 'Start' 10 280 95 30
$pauseButton = Create-Button 'Pause' 115 280 95 30
$resetButton = Create-Button 'Reset' 10 315 95 30
$exitButton = Create-Button 'Ende' 115 315 95 30
$nachtragButton = Create-Button 'Pause nachtragen' 10 350 200 30

$startButton.Add_Click({
    $startZeitForm = New-Object System.Windows.Forms.Form
    $startZeitForm.Text = 'Startzeit'
    $startZeitForm.Size = New-Object System.Drawing.Size(200,120)
    $startZeitForm.StartPosition = 'CenterScreen'
    $startZeitForm.FormBorderStyle = 'FixedDialog'
    $startZeitForm.MaximizeBox = $false
    $startZeitForm.MinimizeBox = $false

    $startZeitTextBox = New-Object System.Windows.Forms.TextBox
    $startZeitTextBox.Location = New-Object System.Drawing.Point(10,20)
    $startZeitTextBox.Size = New-Object System.Drawing.Size(100,20)
    $startZeitTextBox.Font = $titleFont
    $startZeitForm.Controls.Add($startZeitTextBox)

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(10,50)
    $okButton.Size = New-Object System.Drawing.Size(75,25)
    $okButton.Text = 'OK'
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $okButton.Font = $titleFont
    $startZeitForm.Controls.Add($okButton)

    $startZeitForm.AcceptButton = $okButton

    $result = $startZeitForm.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK)
    {
        $startZeitString = $startZeitTextBox.Text
        $global:startZeit = [DateTime]::ParseExact($startZeitString, "HH:mm", $null)
        $global:startZeit = $global:startZeit.Date + $global:startZeit.TimeOfDay
        $global:arbeitszeitEnde = $global:startZeit.AddHours(8)
        $timer.Start()
        Update-Anzeige
    }
})

$pauseButton.Add_Click({
    if (-not $global:istPause) {
        $global:pauseStartZeit = Get-Date
        $global:istPause = $true
        $pauseButton.Text = 'Fortsetzen'
    } else {
        $pauseEndeZeit = Get-Date
        $global:pausenZeit += $pauseEndeZeit - $global:pauseStartZeit
        $global:pauseStartZeit = $null
        $global:istPause = $false
        $pauseButton.Text = 'Pause'
    }
    Update-Anzeige
})

$resetButton.Add_Click({
    $global:startZeit = $null
    $global:pausenZeit = [TimeSpan]::Zero
    $global:pauseStartZeit = $null
    $global:arbeitszeitEnde = $null
    $global:istPause = $false
    $timer.Stop()
    $pauseButton.Text = 'Pause'
    $labelArbeitszeit.Text = "00:00"
    $labelEnde.Text = "00:00"
    $labelVerbleibend.Text = "00:00"
    $labelPausenZeit.Text = "00:00"
})

$exitButton.Add_Click({ $form.Close() })

$nachtragButton.Add_Click({
    $nachtragForm = New-Object System.Windows.Forms.Form
    $nachtragForm.Text = 'Pause nachtragen'
    $nachtragForm.Size = New-Object System.Drawing.Size(250,150)
    $nachtragForm.StartPosition = 'CenterScreen'
    $nachtragForm.FormBorderStyle = 'FixedDialog'
    $nachtragForm.MaximizeBox = $false
    $nachtragForm.MinimizeBox = $false

    $nachtragLabel = New-Object System.Windows.Forms.Label
    $nachtragLabel.Location = New-Object System.Drawing.Point(10,20)
    $nachtragLabel.Size = New-Object System.Drawing.Size(230,20)
    $nachtragLabel.Text = 'Pausendauer (Minuten):'
    $nachtragLabel.Font = $titleFont
    $nachtragForm.Controls.Add($nachtragLabel)

    $nachtragTextBox = New-Object System.Windows.Forms.TextBox
    $nachtragTextBox.Location = New-Object System.Drawing.Point(10,50)
    $nachtragTextBox.Size = New-Object System.Drawing.Size(100,20)
    $nachtragTextBox.Font = $titleFont
    $nachtragForm.Controls.Add($nachtragTextBox)

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(10,80)
    $okButton.Size = New-Object System.Drawing.Size(75,25)
    $okButton.Text = 'OK'
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $okButton.Font = $titleFont
    $nachtragForm.Controls.Add($okButton)

    $nachtragForm.AcceptButton = $okButton

    $result = $nachtragForm.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK)
    {
        $nachtragMinuten = [int]$nachtragTextBox.Text
        $global:pausenZeit += [TimeSpan]::FromMinutes($nachtragMinuten)
        $global:arbeitszeitEnde = $global:arbeitszeitEnde.AddMinutes($nachtragMinuten)
        Update-Anzeige
    }
})

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 60000  # 1 Minute
$timer.Add_Tick({ Update-Anzeige })

$form.Add_Closing({ $timer.Stop() })

[void]$form.ShowDialog()