<Window xmlns="https://github.com/avaloniaui"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        x:Class="Alisonyx.UI.SpectrumAnalyser"
        Width="1200" Height="700"
        Title="Alisonyx.UI — Spectrum Analyser"
        Background="#1E1E1E">

  <Grid RowDefinitions="Auto,*,Auto" ColumnDefinitions="*">
    <!-- Toolbar -->
    <Border Background="#252525" Padding="8" Grid.Row="0">
      <DockPanel>
        <Menu DockPanel.Dock="Left">
          <MenuItem Header="_File"/>
        </Menu>
        <StackPanel Orientation="Horizontal" DockPanel.Dock="Left" Margin="16,0,0,0">
          <Button Content="▶ Start" Margin="4,0"/>
          <Button Content="◼ Stop" Margin="4,0"/>
          <Button Content="⏸ Freeze" Margin="4,0"/>
        </StackPanel>
        <TextBlock Text="RUNNING" Foreground="#00FF66" FontWeight="Bold"
                   VerticalAlignment="Center" HorizontalAlignment="Right"
                   DockPanel.Dock="Right"/>
      </DockPanel>
    </Border>

    <!-- Main content -->
    <Grid Grid.Row="1" ColumnDefinitions="300,*" Margin="8">
      <!-- Left panel: Input/Output Sources -->
      <StackPanel Background="#202020" Padding="10" Spacing="8">
        <TextBlock Text="Input Sources" FontWeight="Bold" Foreground="White"/>
        <ComboBox Items="{Binding InputDevices}" SelectedItem="{Binding SelectedInputDevice}" />
        <CheckBox Content="Ch 1" IsChecked="{Binding Channel1Enabled}" Foreground="White"/>
        <CheckBox Content="Ch 2" IsChecked="{Binding Channel2Enabled}" Foreground="White"/>
        <Separator Margin="0,8"/>
        <TextBlock Text="Output Source" FontWeight="Bold" Foreground="White"/>
        <ComboBox Items="{Binding OutputDevices}" SelectedItem="{Binding SelectedOutputDevice}" />
        <CheckBox Content="Loop" IsChecked="{Binding LoopEnabled}" Foreground="White"/>
        <Button Content="Clear" Margin="0,8,0,0"/>
      </StackPanel>

      <!-- Right panel: Spectrum Analyzer -->
      <Grid Grid.Column="1" Background="#181818" Margin="8">
        <Grid.RowDefinitions>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <DockPanel Grid.Row="0" Margin="0,0,0,4">
          <TextBlock Text="Spectrum Analyzer" FontWeight="Bold" Foreground="White" DockPanel.Dock="Left"/>
          <ComboBox DockPanel.Dock="Right" Width="180" SelectedItem="{Binding VisualizationMode}">
            <ComboBoxItem Content="Spectrum"/>
            <ComboBoxItem Content="Spectrogram"/>
            <ComboBoxItem Content="Comparison"/>
          </ComboBox>
        </DockPanel>

        <!-- Graph placeholder -->
        <Border Grid.Row="1" BorderBrush="#444" BorderThickness="1" CornerRadius="4">
          <TextBlock Text="No data — select channels and press Start"
                     Foreground="#666" HorizontalAlignment="Center"
                     VerticalAlignment="Center"/>
        </Border>
      </Grid>
    </Grid>

    <!-- Footer -->
    <Border Grid.Row="2" Background="#252525" Padding="8">
      <DockPanel>
        <StackPanel Orientation="Horizontal" DockPanel.Dock="Left" Spacing="16">
          <TextBlock Text="RMS: 0.0 dB" Foreground="White"/>
          <TextBlock Text="Peak: 0.0 dB" Foreground="White"/>
          <TextBlock Text="Corr: 0%" Foreground="White"/>
        </StackPanel>
        <StackPanel Orientation="Horizontal" DockPanel.Dock="Right" Spacing="8">
          <Button Content="Snapshot"/>
          <Button Content="Export"/>
        </StackPanel>
      </DockPanel>
    </Border>
  </Grid>
</Window>