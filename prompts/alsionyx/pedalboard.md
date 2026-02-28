interface IPedalBoard 
{
   IConnectionMatrix ConnectionMatrix;
}
interface IPedalBoardConnectionMatrix
{
   List<IPedalboardConnection> ConnectionMatrix;
}
interface IPedalboardConnection
{
  List<IAudioDevice> AudioDevices;
  List<IChannelConnection> ChannelConnections;
  void CreateConnection(IAudioDevice audioDevice, IChannelConnection channelConnection);
  void CreateConnections();

}
public class PedalboardConnection: IPedalboardConnection
{
    public PedalboardConnection()
    {

    }
    public void CreateConnections()
    {

    }
    public void CreateConnection(IAudioDevice audioDevice, IChannelConnection channelConnection)
    {
        //connect 
    }
}
interface IChannelConnection
{
  string inputDeviceChannelName;
  string outputDeviceChannelName;
}

interface IAudioDevice
{
    public void InitializeAudioDevice();
    public void StartAudioDevice();
}

public class SoundFlowAudioDevice: IAudioDevice
{
    public void InitializeAudioDevice()
    {

    }
    public void StartAudioDevice()
    {
        
    }
}

public class TinyGainPlugin: IAudioPlugin
{

}