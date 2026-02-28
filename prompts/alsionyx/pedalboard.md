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
  IAudioDevice InputDevice;
  IAudioDevice OutputDevice;
  List<IChannelConnection> ChannelConnections;
}

interface IChannelConnection
{
  string inputDeviceChannelName;
  string outputDeviceChannelName;
}
