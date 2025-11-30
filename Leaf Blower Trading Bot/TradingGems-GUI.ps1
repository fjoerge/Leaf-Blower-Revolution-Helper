# TradingGems GUI Controller v1.4 - REBUILT

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

# XAML Definition
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="TradingGems Control Center v4.2" 
        Height="630" Width="1280"
        MinHeight="532" MinWidth="750" 
        WindowStartupLocation="Manual"
		Left="2168" Top="0"
        Background="#1E1E1E">
    
    <Window.Resources>
        <Style TargetType="GroupBox">
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderBrush" Value="#3F3F46"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Margin" Value="5"/>
            <Setter Property="Padding" Value="8"/>
        </Style>
        
        <Style TargetType="TextBlock">
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontSize" Value="12"/>
        </Style>
        
        <Style TargetType="Button">
            <Setter Property="Background" Value="#2D2D30"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderBrush" Value="#3F3F46"/>
            <Setter Property="Padding" Value="10,5"/>
            <Setter Property="Margin" Value="3"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
        </Style>
        
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="Margin" Value="5,2"/>
        </Style>
        
        <Style TargetType="TextBox">
            <Setter Property="Background" Value="#2D2D30"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderBrush" Value="#3F3F46"/>
            <Setter Property="Padding" Value="5"/>
            <Setter Property="Margin" Value="3"/>
        </Style>

        <!-- ComboBox Style: gleicher Hintergrund wie TextBox -->
        <Style TargetType="ComboBox">
            <Setter Property="Background" Value="#2D2D30"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderBrush" Value="#3F3F46"/>
            <Setter Property="Padding" Value="3"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ComboBox">
                        <Grid>
                            <ToggleButton Name="ToggleButton"
                                          Background="#2D2D30"
                                          BorderBrush="#3F3F46"
                                          Foreground="White"
                                          IsChecked="{Binding Path=IsDropDownOpen, Mode=TwoWay, RelativeSource={RelativeSource TemplatedParent}}"
                                          ClickMode="Press">
                                <Grid>
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition/>
                                        <ColumnDefinition Width="20"/>
                                    </Grid.ColumnDefinitions>
                                    <ContentPresenter Name="ContentSite"
                                                      IsHitTestVisible="False"
                                                      Content="{TemplateBinding SelectionBoxItem}"
                                                      Margin="4,2,0,2"
                                                      VerticalAlignment="Center"
                                                      HorizontalAlignment="Left"/>
                                    <Path Grid.Column="1"
                                          HorizontalAlignment="Center"
                                          VerticalAlignment="Center"
                                          Data="M 0 0 L 4 4 L 8 0 Z"
                                          Fill="White"/>
                                </Grid>
                            </ToggleButton>
                            <Popup Name="Popup"
                                   Placement="Bottom"
                                   IsOpen="{TemplateBinding IsDropDownOpen}"
                                   AllowsTransparency="True"
                                   Focusable="False"
                                   PopupAnimation="Slide">
                                <Border Background="#2D2D30"
                                        BorderBrush="#3F3F46"
                                        BorderThickness="1">
                                    <ScrollViewer Margin="2" SnapsToDevicePixels="True">
                                        <StackPanel IsItemsHost="True"
                                                    KeyboardNavigation.DirectionalNavigation="Contained"/>
                                    </ScrollViewer>
                                </Border>
                            </Popup>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="ComboBoxItem">
            <Setter Property="Background" Value="#2D2D30"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="Padding" Value="3,1"/>
            <Style.Triggers>
                <Trigger Property="IsHighlighted" Value="True">
                    <Setter Property="Background" Value="#3F3F46"/>
                </Trigger>
                <Trigger Property="IsSelected" Value="True">
                    <Setter Property="Background" Value="#0078D4"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        
        <Style x:Key="StatLabel" TargetType="TextBlock">
            <Setter Property="Foreground" Value="#A0A0A0"/>
            <Setter Property="FontSize" Value="11"/>
            <Setter Property="Margin" Value="0,2"/>
        </Style>
        
        <Style x:Key="StatValue" TargetType="TextBlock">
            <Setter Property="Foreground" Value="#4EC9B0"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Margin" Value="0,2"/>
        </Style>
    </Window.Resources>
    
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        
        <!-- Header -->
        <Grid Grid.Row="0" Margin="0,0,0,10">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            
            <StackPanel Grid.Column="0" Orientation="Horizontal">
                <Button Name="btnStart" Content="▶ START (F8)" Width="120" Height="40"
                        Background="#0E7A0D" FontSize="14"/>
                <Button Name="btnStop" Content="⏸ PAUSE (F8)" Width="120" Height="40"
                        Background="#0078D4" FontSize="14" IsEnabled="False"/>
            </StackPanel>
            
            <StackPanel Grid.Column="2" Orientation="Horizontal" HorizontalAlignment="Center" VerticalAlignment="Center">
                <TextBlock Text="Status: " VerticalAlignment="Center" Foreground="#A0A0A0" FontSize="14"/>
                <TextBlock Name="txtStatus" Text="STOPPED" VerticalAlignment="Center"
                          Foreground="#FFC83D" FontSize="14" FontWeight="Bold" Margin="5,0"/>
            </StackPanel>
            
            <Button Grid.Column="3" Name="btnSaveConfig" Content="💾 Save Config" Width="120" Height="40"
                    Background="#CA5010" FontSize="12"/>
            <Button Grid.Column="4" Name="btnExit" Content="⏹ EXIT (F9)" Width="120" Height="40"
                    Background="#C50F1F" FontSize="14"/>
        </Grid>
        
        <!-- Main content -->
        <Grid Grid.Row="1">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="300"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            
            <!-- Left: Config -->
            <ScrollViewer Grid.Column="0" VerticalScrollBarVisibility="Auto">
                <StackPanel>
                    <GroupBox Header="📦 Item Policies">
                        <StackPanel>
                            <TextBlock Text="Autrotrade ftw =)" FontSize="10" Foreground="#4EC9B0"
                                       TextWrapping="Wrap" Margin="0,0,0,10"/>
                            
                            <CheckBox Name="chkGem" Content="★ Gem Trading" IsChecked="True"/>
                            <StackPanel Orientation="Horizontal" Margin="20,0,0,5">
                                <TextBlock Text="Min Value:" VerticalAlignment="Center" Width="70"/>
                                <Grid Width="70">
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="18"/>
                                    </Grid.ColumnDefinitions>
                                    <Grid.RowDefinitions>
                                        <RowDefinition Height="*"/>
                                        <RowDefinition Height="*"/>
                                    </Grid.RowDefinitions>
                                    <TextBox Name="txtGemMinValue"
                                             Grid.RowSpan="2"
                                             Grid.Column="0"
                                             Text="3"
                                             HorizontalContentAlignment="Center"/>
                                    <Button Name="btnGemMinUp"
                                            Grid.Row="0"
                                            Grid.Column="1"
                                            Content="▲"
                                            Padding="0"
                                            FontSize="9"/>
                                    <Button Name="btnGemMinDown"
                                            Grid.Row="1"
                                            Grid.Column="1"
                                            Content="▼"
                                            Padding="0"
                                            FontSize="9"/>
                                </Grid>
                            </StackPanel>
                            
                            <CheckBox Name="chkBeer" Content="🍺 Beer Trading" IsChecked="True"/>
                            <CheckBox Name="chkBorb" Content="🤢 Borb Trading" IsChecked="True"/>
                            <CheckBox Name="chkCheese" Content="🧀 Cheese Trading" IsChecked="False"/>
                            <CheckBox Name="chkMulch" Content="🌿 Mulch Trading" IsChecked="True"/>
                        </StackPanel>
                    </GroupBox>
                    
                    <GroupBox Header="⚙️ Main Settings">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="70"/>
                            </Grid.ColumnDefinitions>
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="Auto"/>
                            </Grid.RowDefinitions>
                            
                            <TextBlock Grid.Row="0" Grid.Column="0" Text="Collect Interval (s):" VerticalAlignment="Center"/>
                            <TextBox Grid.Row="0" Grid.Column="1" Name="txtCollectInterval" Text="15"/>
                            
                            <TextBlock Grid.Row="1" Grid.Column="0" Text="Max Trades:" VerticalAlignment="Center"/>
                            <TextBox Grid.Row="1" Grid.Column="1" Name="txtMaxTrades" Text="9"/>
                            
                            <TextBlock Grid.Row="2" Grid.Column="0" Text="Refresh Interval:" VerticalAlignment="Center"/>
                            <TextBox Grid.Row="2" Grid.Column="1" Name="txtRefreshInterval" Text="5"/>
                            
                            <TextBlock Grid.Row="3" Grid.Column="0" Text="Log Mode:" VerticalAlignment="Center"/>
                            <ComboBox Grid.Row="3" Grid.Column="1" Name="cmbLogMode">
                                <ComboBoxItem Content="STATS" IsSelected="True"/>
                                <ComboBoxItem Content="INFO"/>
                                <ComboBoxItem Content="DEBUG"/>
                            </ComboBox>
                        </Grid>
                    </GroupBox>
                    
                    <GroupBox Header="🔧 Advanced">
                        <StackPanel>
                            <CheckBox Name="chkAutoCalib" Content="Auto Calibration" IsChecked="True"/>
                            <CheckBox Name="chkEnableGemStats" Content="Enable Gem Stats" IsChecked="True"/>
                            <TextBlock Text="Screenshot Mode:" Margin="0,5,0,2"/>
                            <ComboBox Name="cmbScreenshotMode">
                                <ComboBoxItem Content="OFF"/>
                                <ComboBoxItem Content="UNKNOWN" IsSelected="True"/>
                                <ComboBoxItem Content="ALL"/>
                            </ComboBox>
                        </StackPanel>
                    </GroupBox>
                </StackPanel>
            </ScrollViewer>
            
            <!-- Right: Stats + Log -->
            <Grid Grid.Column="1" Margin="10,0,0,0">
                <Grid.RowDefinitions>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="0"/>
                </Grid.RowDefinitions>
                
                <ScrollViewer Grid.Row="0" VerticalScrollBarVisibility="Auto">
                    <StackPanel>
                        <GroupBox Header="📊 Session Statistics">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="*"/>
                                </Grid.ColumnDefinitions>
                                
                                <StackPanel Grid.Column="0">
                                    <TextBlock Text="Start Time" Style="{StaticResource StatLabel}"/>
                                    <TextBlock Name="txtStartTime" Text="--:--:--" Style="{StaticResource StatValue}"/>
                                    <TextBlock Text="Duration" Style="{StaticResource StatLabel}" Margin="0,10,0,0"/>
                                    <TextBlock Name="txtDuration" Text="00:00:00" Style="{StaticResource StatValue}"/>
                                </StackPanel>
                                
                                <StackPanel Grid.Column="1">
                                    <TextBlock Text="Total Trades" Style="{StaticResource StatLabel}"/>
                                    <TextBlock Name="txtTotalTrades" Text="0" Style="{StaticResource StatValue}"/>
                                    <TextBlock Text="Trades/Hour" Style="{StaticResource StatLabel}" Margin="0,10,0,0"/>
                                    <TextBlock Name="txtTradesPerHour" Text="0" Style="{StaticResource StatValue}"/>
                                </StackPanel>
                                
                                <StackPanel Grid.Column="2">
									<TextBlock Text="Active Slots" Style="{StaticResource StatLabel}"/>
									<TextBlock Name="txtActiveSlots" Text="0/9" Style="{StaticResource StatValue}"/>
									<TextBlock Text="Slot Util (%)" Style="{StaticResource StatLabel}" Margin="0,10,0,0"/>
									<TextBlock Name="txtSlotUtilPerHour" Text="0%" Style="{StaticResource StatValue}"/>
								</StackPanel>
                            </Grid>
                        </GroupBox>
                        
                        <GroupBox Header="💎 Gem Statistics">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="*"/>
                                </Grid.ColumnDefinitions>
                                
                                <StackPanel Grid.Column="0">
                                    <TextBlock Text="Total Gems" Style="{StaticResource StatLabel}"/>
                                    <TextBlock Name="txtTotalGems" Text="0" Style="{StaticResource StatValue}"/>
                                    <TextBlock Text="Gems/Hour" Style="{StaticResource StatLabel}" Margin="0,10,0,0"/>
                                    <TextBlock Name="txtGemsPerHour" Text="0.00" Style="{StaticResource StatValue}"/>
                                </StackPanel>
                                
                                <StackPanel Grid.Column="1">
                                    <TextBlock Text="Gem Trades" Style="{StaticResource StatLabel}"/>
                                    <TextBlock Name="txtGemTrades" Text="0" Style="{StaticResource StatValue}"/>
                                    <TextBlock Text="Avg Gems/Trade" Style="{StaticResource StatLabel}" Margin="0,10,0,0"/>
                                    <TextBlock Name="txtAvgGemsPerTrade" Text="0.00" Style="{StaticResource StatValue}"/>
                                </StackPanel>
                                
                                <StackPanel Grid.Column="2">
                                    <TextBlock Text="High Value (10-13)" Style="{StaticResource StatLabel}"/>
                                    <TextBlock Name="txtHighValue" Text="0 (0%)" Style="{StaticResource StatValue}"/>
                                    <TextBlock Text="Success Rate" Style="{StaticResource StatLabel}" Margin="0,10,0,0"/>
                                    <TextBlock Name="txtSuccessRate" Text="0%" Style="{StaticResource StatValue}"/>
                                </StackPanel>
                            </Grid>
                        </GroupBox>
                        
                        <GroupBox Header="📈 Item Distribution">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="120"/>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="60"/>
                                    <ColumnDefinition Width="80"/>
                                </Grid.ColumnDefinitions>
                                <Grid.RowDefinitions>
                                    <RowDefinition Height="25"/>
                                    <RowDefinition Height="25"/>
                                    <RowDefinition Height="25"/>
                                    <RowDefinition Height="25"/>
                                    <RowDefinition Height="25"/>
                                </Grid.RowDefinitions>
                                
                                <!-- Gems -->
								<!-- Old Value Gems:   #4EC9B0 -->
								<!-- Old Value Beer:   #FFC83D -->
								<!-- Old Value Cheese: #F48771 -->
								<!-- Old Value Mulch:  #6CB52D -->
								
                                <TextBlock Grid.Row="0" Grid.Column="0" Text="★ Gems" VerticalAlignment="Center"/>
                                <ProgressBar Grid.Row="0" Grid.Column="1" Name="barGems" Minimum="0" Maximum="100"
                                             Value="0" Height="18" Foreground="#F48771"/>
                                <TextBlock Grid.Row="0" Grid.Column="2" Name="txtGemPercent" Text="0%"
                                           VerticalAlignment="Center" HorizontalAlignment="Left" Margin="4,0,0,0"/>
                                <TextBlock Grid.Row="0" Grid.Column="3" Name="txtGemTotal" Text="0"
                                           VerticalAlignment="Center" HorizontalAlignment="Right"/>
                                										   
                                <!-- Beer -->
                                <TextBlock Grid.Row="1" Grid.Column="0" Text="🍺 Beer" VerticalAlignment="Center"/>
                                <ProgressBar Grid.Row="1" Grid.Column="1" Name="barBeer" Minimum="0" Maximum="100"
                                             Value="0" Height="18" Foreground="#BD8D5C"/>
                                <TextBlock Grid.Row="1" Grid.Column="2" Name="txtBeerPercent" Text="0%"
                                           VerticalAlignment="Center" HorizontalAlignment="Left" Margin="4,0,0,0"/>
                                <TextBlock Grid.Row="1" Grid.Column="3" Name="txtBeerTotal" Text="0"
                                           VerticalAlignment="Center" HorizontalAlignment="Right"/>
								
                                <!-- Borb -->
                                <TextBlock Grid.Row="2" Grid.Column="0" Text="🤢 Borb" VerticalAlignment="Center"/>
                                <ProgressBar Grid.Row="2" Grid.Column="1" Name="barBorb" Minimum="0" Maximum="100"
                                             Value="0" Height="18" Foreground="#45B914"/>
                                <TextBlock Grid.Row="2" Grid.Column="2" Name="txtBorbPercent" Text="0%"
                                           VerticalAlignment="Center" HorizontalAlignment="Left" Margin="4,0,0,0"/>
                                <TextBlock Grid.Row="2" Grid.Column="3" Name="txtBorbTotal" Text="0"
                                           VerticalAlignment="Center" HorizontalAlignment="Right"/>
                                           		   
                                <!-- Cheese -->
                                <TextBlock Grid.Row="3" Grid.Column="0" Text="🧀 Cheese" VerticalAlignment="Center"/>
                                <ProgressBar Grid.Row="3" Grid.Column="1" Name="barCheese" Minimum="0" Maximum="100"
                                             Value="0" Height="18" Foreground="#FFC83D"/>
                                <TextBlock Grid.Row="3" Grid.Column="2" Name="txtCheesePercent" Text="0%"
                                           VerticalAlignment="Center" HorizontalAlignment="Left" Margin="4,0,0,0"/>
                                <TextBlock Grid.Row="3" Grid.Column="3" Name="txtCheeseTotal" Text="0"
                                           VerticalAlignment="Center" HorizontalAlignment="Right"/>

                                <!-- Mulch -->
                                <TextBlock Grid.Row="4" Grid.Column="0" Text="🌿 Mulch" VerticalAlignment="Center"/>
                                <ProgressBar Grid.Row="4" Grid.Column="1" Name="barMulch" Minimum="0" Maximum="100"
                                             Value="0" Height="18" Foreground="#4D3925"/>
                                <TextBlock Grid.Row="4" Grid.Column="2" Name="txtMulchPercent" Text="0%"
                                           VerticalAlignment="Center" HorizontalAlignment="Left" Margin="4,0,0,0"/>
                                <TextBlock Grid.Row="4" Grid.Column="3" Name="txtMulchTotal" Text="0"
                                           VerticalAlignment="Center" HorizontalAlignment="Right"/>
                                
                            </Grid>
                        </GroupBox>
                    </StackPanel>
                </ScrollViewer>
                
                <GroupBox Grid.Row="1" Header="📝 Activity Log">
                    <Grid>
                        <Grid.RowDefinitions>
                            <RowDefinition Height="*"/>
                            <RowDefinition Height="Auto"/>
                        </Grid.RowDefinitions>
                        
                        <ScrollViewer Grid.Row="0" Name="logScrollViewer" VerticalScrollBarVisibility="Auto">
                            <TextBlock Name="txtLog" TextWrapping="Wrap" FontFamily="Consolas" FontSize="11"
                                      Padding="5" Background="#252526"/>
                        </ScrollViewer>
                        
                        <Button Grid.Row="1" Name="btnClearLog" Content="Clear Log"
                               HorizontalAlignment="Right" Width="100"/>
                    </Grid>
                </GroupBox>
            </Grid>
        </Grid>
    </Grid>
</Window>
"@

# Parse XAML
$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($xaml))
$window = [Windows.Markup.XamlReader]::Load($reader)

# Get controls
$controls = @{}
@(
    'btnStart','btnStop','btnExit','btnSaveConfig','btnClearLog',
    'txtStatus','txtStartTime','txtDuration','txtTotalTrades','txtTradesPerHour',
    'txtRefreshes','txtActiveSlots','txtTotalGems','txtGemsPerHour','txtGemTrades',
    'txtAvgGemsPerTrade','txtHighValue','txtSuccessRate','txtLog',
    'chkGem','chkBeer','chkMulch','chkCheese','chkBorb',
    'txtGemMinValue','txtCollectInterval','txtMaxTrades','txtRefreshInterval',
    'cmbLogMode','chkAutoCalib','chkEnableGemStats','cmbScreenshotMode',
    'barGems','barBeer','barMulch','barCheese','barBorb',
    'txtGemPercent','txtBeerPercent','txtMulchPercent','txtCheesePercent','txtBorbPercent',
    'txtGemTotal','txtBeerTotal','txtMulchTotal','txtCheeseTotal','txtBorbTotal',
    'logScrollViewer',
    'btnGemMinUp','btnGemMinDown',
    'txtSlotUtilPerHour'
) | ForEach-Object {
    $controls[$_] = $window.FindName($_)
}


# ===== Global state + Logik (aus alter Datei wiederhergestellt) =====

$script:statsFile = Join-Path $PSScriptRoot "TradeStats.json"
$script:configFile = Join-Path $PSScriptRoot "TradeConfig.json"
$script:lastStatsUpdate = [DateTime]::MinValue
$script:stats = @{
    StartedTrades = 0
    RefreshCount = 0
    GemTrades = 0
    BeerTrades = 0
    BorbTrades = 0
    CheeseTrades = 0
    MulchTrades = 0
    GemsTotal = 0
    GemValue1Count = 0
    GemValue2Count = 0
    GemValue3Count = 0
    GemValue4Count = 0
    GemValue5Count = 0
    GemValue6Count = 0
    GemValue7Count = 0
    GemValue8Count = 0
    GemValue9Count = 0
    GemValue10Count = 0
    GemValue11Count = 0
    GemValue12Count = 0
    GemValue13Count = 0
    GemValue14Count = 0
    GemValue15Count = 0
    GemValue16Count = 0
    GemValue17Count = 0
    GemValue18Count = 0
    SuccessfulStarts = 0
    FailedStarts = 0
    StartAttempts = 0
    LastActiveSlots = 0
    ScriptStartTime = Get-Date
    IsRunning = $false
}

# Timer
$script:timer = New-Object System.Windows.Threading.DispatcherTimer
$script:timer.Interval = [TimeSpan]::FromMilliseconds(500)

# Helper Win32
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")]
    public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, int dwExtraInfo);
}
"@

function Write-GuiLog {
    param([string]$Message, [string]$Color = "White")
    $timestamp = Get-Date -Format "HH:mm:ss"
    $logText = "[$timestamp] $Message"
    $window.Dispatcher.Invoke([action]{
        $run = New-Object System.Windows.Documents.Run
        $run.Text = "$logText`n"
        switch ($Color) {
            "Green"  { $run.Foreground = "#4EC9B0" }
            "Yellow" { $run.Foreground = "#FFC83D" }
            "Red"    { $run.Foreground = "#F48771" }
            "Cyan"   { $run.Foreground = "#4FC1FF" }
            default  { $run.Foreground = "White" }
        }
        if ($controls['txtLog'].Inlines.Count -gt 500) {
            $controls['txtLog'].Inlines.Clear()
        }
        $controls['txtLog'].Inlines.Add($run)
        $controls['logScrollViewer'].ScrollToBottom()
    })
}

function Send-KeyToBot {
    param([byte]$VirtualKey)
    try {
        $processes = Get-Process -Name "powershell" -ErrorAction SilentlyContinue
        foreach ($proc in $processes) {
            if ($proc.MainWindowTitle -like "*TradingGems*" -or $proc.MainWindowTitle -like "*Trade*" -or $proc.Id -ne $PID) {
                $hwnd = $proc.MainWindowHandle
                if ($hwnd -ne [IntPtr]::Zero) {
                    [Win32]::SetForegroundWindow($hwnd) | Out-Null
                    Start-Sleep -Milliseconds 150
                    [Win32]::keybd_event($VirtualKey, 0, 0, 0)
                    Start-Sleep -Milliseconds 50
                    [Win32]::keybd_event($VirtualKey, 0, 2, 0)
                    Write-GuiLog "Key sent to bot (PID: $($proc.Id))" "Cyan"
                    return $true
                }
            }
        }
        Write-GuiLog "Bot window not found!" "Yellow"
        return $false
    }
    catch {
        Write-GuiLog "Error sending key: $_" "Red"
        return $false
    }
}

function Update-Statistics {
    if (-not (Test-Path $script:statsFile)) { return }
    try {
        $fileInfo = Get-Item $script:statsFile
        if ($fileInfo.LastWriteTime -le $script:lastStatsUpdate) { return }
        $script:lastStatsUpdate = $fileInfo.LastWriteTime
        $json = Get-Content $script:statsFile -Raw -Encoding UTF8
        $loadedStats = $json | ConvertFrom-Json

        $loadedStats.PSObject.Properties | ForEach-Object {
            if ($script:stats.ContainsKey($_.Name)) {
                $script:stats[$_.Name] = $_.Value
            }
        }

        if ($loadedStats.ScriptStartTime -is [string]) {
            try { $script:stats.ScriptStartTime = [DateTime]::Parse($loadedStats.ScriptStartTime) } catch {}
        }
        if ($loadedStats.PSObject.Properties.Match("IsRunning").Count -gt 0) {
            $script:stats.IsRunning = $loadedStats.IsRunning
        }

        $duration = (Get-Date) - $script:stats.ScriptStartTime
        $hours = [Math]::Max($duration.TotalHours, 0.0001)
        $tradesPerHour = $script:stats.SuccessfulStarts / $hours
        $gemsPerHour   = $script:stats.GemsTotal / $hours
        $avgGemsPerTrade = if ($script:stats.GemTrades -gt 0) {
            $script:stats.GemsTotal / $script:stats.GemTrades
        } else { 0 }

        $highValueCount = $script:stats.GemValue13Count + $script:stats.GemValue14Count +
                          $script:stats.GemValue15Count + $script:stats.GemValue16Count +
                          $script:stats.GemValue17Count + $script:stats.GemValue18Count
        $highValuePercent = if ($script:stats.GemTrades -gt 0) {
            100.0 * $highValueCount / $script:stats.GemTrades
        } else { 0 }

        $successRate = if ($script:stats.StartAttempts -gt 0) {
            100.0 * $script:stats.SuccessfulStarts / $script:stats.StartAttempts
        } else { 0 }

        $window.Dispatcher.Invoke([action]{
            if ($script:stats.IsRunning) {
                $controls['btnStart'].IsEnabled = $false
                $controls['btnStop'].IsEnabled  = $true
                $controls['txtStatus'].Text     = "RUNNING"
                $controls['txtStatus'].Foreground = "#4EC9B0"
            } else {
                $controls['btnStart'].IsEnabled = $true
                $controls['btnStop'].IsEnabled  = $false
                $controls['txtStatus'].Text     = "PAUSED"
                $controls['txtStatus'].Foreground = "#FFC83D"
            }

            $controls['txtStartTime'].Text     = $script:stats.ScriptStartTime.ToString("HH:mm:ss")
            $controls['txtDuration'].Text      = "{0:hh\:mm\:ss}" -f $duration
            $controls['txtTotalTrades'].Text   = $script:stats.SuccessfulStarts
            $controls['txtTradesPerHour'].Text = "{0:N1}" -f $tradesPerHour
            # $controls['txtRefreshes'].Text     = $script:stats.RefreshCount
			
            # MaxTrades aus Config (Fallback 9)
			$maxTrades = 9
			try {
				if (Test-Path $script:configFile) {
					$cfg = Get-Content $script:configFile -Raw -Encoding UTF8 | ConvertFrom-Json
					if ($cfg.MaxTrades) { $maxTrades = [int]$cfg.MaxTrades }
				}
			} catch { }

			$active = $script:stats.LastActiveSlots
			if ($maxTrades -le 0) { $maxTrades = 1 }
			$slotUtilPerHour = [double]$loadedStats.SlotUtilPerHour
			
			$controls['txtSlotUtilPerHour'].Text = "{0:N1}%" -f $slotUtilPerHour
			$controls['txtActiveSlots'].Text = "$active/$maxTrades"
            $controls['txtTotalGems'].Text       = $script:stats.GemsTotal
            $controls['txtGemsPerHour'].Text     = "{0:N2}" -f $gemsPerHour
            $controls['txtGemTrades'].Text       = $script:stats.GemTrades
            $controls['txtAvgGemsPerTrade'].Text = "{0:N2}" -f $avgGemsPerTrade
            $controls['txtHighValue'].Text       = "$highValueCount ({0:N1}%)" -f $highValuePercent
            $controls['txtSuccessRate'].Text     = "{0:N0}%" -f $successRate

            $totalTrades = $script:stats.SuccessfulStarts
            if ($totalTrades -gt 0) {
                $gemPct    = 100.0 * $script:stats.GemTrades      / $totalTrades
                $beerPct   = 100.0 * $script:stats.BeerTrades     / $totalTrades
                $borbPct   = 100.0 * $script:stats.BorbTrades     / $totalTrades
                $cheesePct = 100.0 * $script:stats.CheeseTrades   / $totalTrades
                $mulchPct  = 100.0 * $script:stats.MulchTrades    / $totalTrades

                $controls['barGems'].Value        = $gemPct
                $controls['barBeer'].Value        = $beerPct
                $controls['barBorb'].Value        = $BorbPct
                $controls['barCheese'].Value      = $cheesePct
                $controls['barMulch'].Value       = $mulchPct

                $controls['txtGemPercent'].Text       = "{0:N1}%" -f $gemPct
                $controls['txtBeerPercent'].Text      = "{0:N1}%" -f $beerPct
                $controls['txtBorbPercent'].Text      = "{0:N1}%" -f $borbPct
                $controls['txtCheesePercent'].Text    = "{0:N1}%" -f $cheesePct
                $controls['txtMulchPercent'].Text     = "{0:N1}%" -f $mulchPct

                $controls['txtGemTotal'].Text        = $script:stats.GemTrades
                $controls['txtBeerTotal'].Text       = $script:stats.BeerTrades
                $controls['txtBorbTotal'].Text       = $script:stats.BorbTrades
                $controls['txtCheeseTotal'].Text     = $script:stats.CheeseTrades
                $controls['txtMulchTotal'].Text      = $script:stats.MulchTrades
            }
        })
    }
    catch {
        Write-GuiLog "Error updating stats: $_" "Yellow"
    }
}

function Save-Configuration {
    param([bool]$ShowLog = $true)
    $config = @{
        ItemPolicies = @{
            Gem = @{
                Start        = $controls['chkGem'].IsChecked
                MinValue     = [int]$controls['txtGemMinValue'].Text
                Tolerance    = 20
                NeedsGemValue = $true
            }
            Beer = @{
                Start        = $controls['chkBeer'].IsChecked
                Tolerance    = 15
                NeedsGemValue = $false
            }
            Borb = @{
                Start        = $controls['chkBorb'].IsChecked
                Tolerance    = 15
                NeedsGemValue = $false
            }
            Cheese = @{
                Start        = $controls['chkCheese'].IsChecked
                Tolerance    = 10
                NeedsGemValue = $false
            }
            Mulch = @{
                Start        = $controls['chkMulch'].IsChecked
                Tolerance    = 10
                NeedsGemValue = $false
            }
        }
        CollectIntervalSeconds = [int]$controls['txtCollectInterval'].Text
        MaxTrades              = [int]$controls['txtMaxTrades'].Text
        RefreshIntervalRowsFull= [int]$controls['txtRefreshInterval'].Text
        LogMode                = $controls['cmbLogMode'].SelectedItem.Content
        AutoCalibEnabled       = $controls['chkAutoCalib'].IsChecked
        EnableGemStats         = $controls['chkEnableGemStats'].IsChecked
        StatsGemScreenshotMode = $controls['cmbScreenshotMode'].SelectedItem.Content
    }
    $config | ConvertTo-Json -Depth 10 | Set-Content $script:configFile -Encoding UTF8
    if ($ShowLog) {
        Write-GuiLog "Config gespeichert (passiert aber auch automatisch beim aendern;) )" "Green"
    }
}

function Load-Configuration {
    if (Test-Path $script:configFile) {
        try {
            $config = Get-Content $script:configFile -Raw -Encoding UTF8 | ConvertFrom-Json
            $controls['chkGem'].IsChecked         = $config.ItemPolicies.Gem.Start
            $controls['txtGemMinValue'].Text      = $config.ItemPolicies.Gem.MinValue
            $controls['chkBeer'].IsChecked        = $config.ItemPolicies.Beer.Start
            $controls['chkBorb'].IsChecked        = $config.ItemPolicies.Borb.Start
            $controls['chkMulch'].IsChecked       = $config.ItemPolicies.Mulch.Start
            $controls['chkCheese'].IsChecked      = $config.ItemPolicies.Cheese.Start

            $controls['txtCollectInterval'].Text  = $config.CollectIntervalSeconds
            $controls['txtMaxTrades'].Text        = $config.MaxTrades
            $controls['txtRefreshInterval'].Text  = $config.RefreshIntervalRowsFull

            for ($i = 0; $i -lt $controls['cmbLogMode'].Items.Count; $i++) {
                if ($controls['cmbLogMode'].Items[$i].Content -eq $config.LogMode) {
                    $controls['cmbLogMode'].SelectedIndex = $i; break
                }
            }
            $controls['chkAutoCalib'].IsChecked    = $config.AutoCalibEnabled
            $controls['chkEnableGemStats'].IsChecked = $config.EnableGemStats

            for ($i = 0; $i -lt $controls['cmbScreenshotMode'].Items.Count; $i++) {
                if ($controls['cmbScreenshotMode'].Items[$i].Content -eq $config.StatsGemScreenshotMode) {
                    $controls['cmbScreenshotMode'].SelectedIndex = $i; break
                }
            }
            Write-GuiLog "Config geladen" "Cyan"
        }
        catch {
            Write-GuiLog "Error loading config: $_" "Red"
        }
    }
}

# Event handlers
$controls['btnStart'].Add_Click({
    Write-GuiLog "START gedrueckt - sende F8 an Bot..." "Green"
    Send-KeyToBot 0x77
})
$controls['btnStop'].Add_Click({
    Write-GuiLog "PAUSE gedrueckt - sende F8 an Bot..." "Yellow"
    Send-KeyToBot 0x77
})
$controls['btnExit'].Add_Click({
    $result = [System.Windows.MessageBox]::Show(
        "Bot UND GUI beenden?",
        "Confirm Exit",
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Question
    )
    if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
        Write-GuiLog "Beende Bot..." "Red"
        Send-KeyToBot 0x78
        Start-Sleep -Milliseconds 500
        Get-Process -Name "powershell" -ErrorAction SilentlyContinue | Where-Object {
            $_.MainWindowTitle -like "*TradingGems*" -or
            $_.MainWindowTitle -like "*Trade*" -or
            $_.Id -ne $PID
        } | Stop-Process -Force -ErrorAction SilentlyContinue
        Write-GuiLog "Bot beendet. Schliesse GUI..." "Yellow"
        Start-Sleep -Milliseconds 500
        $window.Close()
    }
})
$controls['btnSaveConfig'].Add_Click({ Save-Configuration })
$controls['btnClearLog'].Add_Click({
    $controls['txtLog'].Inlines.Clear()
    Write-GuiLog "Log cleared" "Cyan"
})

# Gem MinValue Up/Down
$controls['btnGemMinUp'].Add_Click({
    $value = 0
    [int]::TryParse($controls['txtGemMinValue'].Text, [ref]$value) | Out-Null
    $value++
    $controls['txtGemMinValue'].Text = $value.ToString()
})
$controls['btnGemMinDown'].Add_Click({
    $value = 0
    [int]::TryParse($controls['txtGemMinValue'].Text, [ref]$value) | Out-Null
    if ($value -gt 0) { $value-- }
    $controls['txtGemMinValue'].Text = $value.ToString()
})

# Auto-Save: CheckBoxen
@('chkGem','chkBeer','chkMulch','chkCheese','chkBorb'
  'chkAutoCalib','chkEnableGemStats') | ForEach-Object {
    $controls[$_].Add_Checked({   Save-Configuration -ShowLog $false })
    $controls[$_].Add_Unchecked({ Save-Configuration -ShowLog $false })
}

# Auto-Save: TextBoxen
@('txtGemMinValue','txtCollectInterval','txtMaxTrades','txtRefreshInterval') | ForEach-Object {
    $controls[$_].Add_TextChanged({ Save-Configuration -ShowLog $false })
}

# Auto-Save: ComboBoxen
@('cmbLogMode','cmbScreenshotMode') | ForEach-Object {
    $controls[$_].Add_SelectionChanged({ Save-Configuration -ShowLog $false })
}

# Timer tick
$script:timer.Add_Tick({ Update-Statistics })

# Window events
$window.Add_Loaded({
    Load-Configuration
    Write-GuiLog "TradingGems GUI v1.4 gestartet" "Cyan"
    Write-GuiLog "Hotkeys: F8 = Start/Pause | F9 = Exit" "Cyan"
    Write-GuiLog "Stats file: $script:statsFile" "Cyan"
    Write-GuiLog "Config file: $script:configFile" "Cyan"
    Write-GuiLog "" "White"
    Write-GuiLog "Warte auf Bot..." "Yellow"
    $script:timer.Start()
})
$window.Add_Closing({ $script:timer.Stop() })

$window.ShowDialog() | Out-Null
