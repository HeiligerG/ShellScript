Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$global:startZeit = $null
$global:pausenZeit = [TimeSpan]::Zero
$global:pauseStartZeit = $null
$global:arbeitszeitEnde = $null

function Update-Anzeige {
    if ($global:startZeit -eq $null) {
        return
    }
    $aktuelleZeit = Get-Date
    $gearbeiteteZeit = $aktuelleZeit - $global:startZeit - $global:pausenZeit
    if ($global:pauseStartZeit -ne $null) {
        $gearbeiteteZeit -= ($aktuelleZeit - $global:pauseStartZeit)
    }
    $verbleibendeZeit = $global:arbeitszeitEnde - $aktuelleZeit + $global:pausenZeit
    if ($verbleibendeZeit.TotalSeconds -lt 0) {
        $verbleibendeZeit = [TimeSpan]::Zero
    }
    $labelArbeitszeit.Text = "Arbeitszeit: " + $gearbeiteteZeit.ToString("hh\:mm")
    $labelEnde.Text = "Ende: " + $global:arbeitszeitEnde.ToString("HH:mm")
    $labelVerbleibend.Text = "Verbleibend: " + $verbleibendeZeit.ToString("hh\:mm")
}

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Arbeitszeit-Tracker'
$form.Size = New-Object System.Drawing.Size(200,180)
$form.StartPosition = 'Manual'
$form.Location = New-Object System.Drawing.Point(0, 0)
$form.TopMost = $true

$labelArbeitszeit = New-Object System.Windows.Forms.Label
$labelArbeitszeit.Location = New-Object System.Drawing.Point(10,10)
$labelArbeitszeit.Size = New-Object System.Drawing.Size(180,20)
$labelArbeitszeit.Text = 'Arbeitszeit: 00:00'
$form.Controls.Add($labelArbeitszeit)

$labelEnde = New-Object System.Windows.Forms.Label
$labelEnde.Location = New-Object System.Drawing.Point(10,30)
$labelEnde.Size = New-Object System.Drawing.Size(180,20)
$labelEnde.Text = 'Ende: --:--'
$form.Controls.Add($labelEnde)

$labelVerbleibend = New-Object System.Windows.Forms.Label
$labelVerbleibend.Location = New-Object System.Drawing.Point(10,50)
$labelVerbleibend.Size = New-Object System.Drawing.Size(180,20)
$labelVerbleibend.Text = 'Verbleibend: 00:00'
$form.Controls.Add($labelVerbleibend)

$startButton = New-Object System.Windows.Forms.Button
$startButton.Location = New-Object System.Drawing.Point(10,80)
$startButton.Size = New-Object System.Drawing.Size(80,30)
$startButton.Text = 'Start'
$form.Controls.Add($startButton)

$pauseButton = New-Object System.Windows.Forms.Button
$pauseButton.Location = New-Object System.Drawing.Point(100,80)
$pauseButton.Size = New-Object System.Drawing.Size(80,30)
$pauseButton.Text = 'Pause'
$pauseButton.Enabled = $false
$form.Controls.Add($pauseButton)

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 60000  # 1 Minute
$timer.Add_Tick({ Update-Anzeige })

$startButton.Add_Click({
    $startZeitForm = New-Object System.Windows.Forms.Form
    $startZeitForm.Text = 'Startzeit eingeben'
    $startZeitForm.Size = New-Object System.Drawing.Size(250,150)
    $startZeitForm.StartPosition = 'CenterScreen'

    $startZeitLabel = New-Object System.Windows.Forms.Label
    $startZeitLabel.Location = New-Object System.Drawing.Point(10,20)
    $startZeitLabel.Size = New-Object System.Drawing.Size(230,20)
    $startZeitLabel.Text = 'Startzeit (HH:mm):'
    $startZeitForm.Controls.Add($startZeitLabel)

    $startZeitTextBox = New-Object System.Windows.Forms.TextBox
    $startZeitTextBox.Location = New-Object System.Drawing.Point(10,40)
    $startZeitTextBox.Size = New-Object System.Drawing.Size(100,20)
    $startZeitForm.Controls.Add($startZeitTextBox)

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(10,70)
    $okButton.Size = New-Object System.Drawing.Size(75,23)
    $okButton.Text = 'OK'
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $startZeitForm.Controls.Add($okButton)

    $startZeitForm.AcceptButton = $okButton

    $result = $startZeitForm.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK)
    {
        $startZeitString = $startZeitTextBox.Text
        $global:startZeit = [DateTime]::ParseExact($startZeitString, "HH:mm", $null)
        $global:startZeit = $global:startZeit.Date + $global:startZeit.TimeOfDay
        $global:arbeitszeitEnde = $global:startZeit.AddHours(8)
        $pauseButton.Enabled = $true
        $startButton.Enabled = $false
        $timer.Start()
        Update-Anzeige
    }
})

$pauseButton.Add_Click({
    if ($global:pauseStartZeit -eq $null) {
        $global:pauseStartZeit = Get-Date
        $pauseButton.Text = 'Fortsetzen'
    } else {
        $pauseEndeZeit = Get-Date
        $global:pausenZeit += $pauseEndeZeit - $global:pauseStartZeit
        $global:pauseStartZeit = $null
        $pauseButton.Text = 'Pause'
    }
    Update-Anzeige
})

$form.Add_Closing({ $timer.Stop() })

[void]$form.ShowDialog()