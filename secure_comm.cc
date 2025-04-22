#include "ns3/core-module.h"
#include "ns3/network-module.h"
#include "ns3/internet-module.h"
#include "ns3/point-to-point-module.h"
#include "ns3/applications-module.h"
#include "ns3/socket.h"

using namespace ns3;

std::string EncryptAES(const std::string &data, const std::string &key) {
    std::string encrypted = data;
    for (size_t i = 0; i < data.size(); ++i)
        encrypted[i] ^= key[i % key.size()];
    return encrypted;
}

std::string ComputeHMAC(const std::string &data, const std::string &key) {
    return std::to_string(std::hash<std::string>()(data + key));
}

void ReceivePacket(Ptr<Socket> socket) {
    Address from;
    Ptr<Packet> packet = socket->RecvFrom(from);
    uint32_t size = packet->GetSize();
    uint8_t *buffer = new uint8_t[size];
    packet->CopyData(buffer, size);
    std::string msg(reinterpret_cast<char*>(buffer), size);
    delete[] buffer;

    size_t sep = msg.find(":");
    std::string encrypted = msg.substr(0, sep);
    std::string receivedHmac = msg.substr(sep + 1);
    std::string expectedHmac = ComputeHMAC(encrypted, "hmackey");

    if (receivedHmac == expectedHmac) {
        std::string decrypted = EncryptAES(encrypted, "securekey");
        std::cout << "[Node 1] ✅ Decrypted message: " << decrypted << std::endl;
    } else {
        std::cout << "[Node 1] ❌ HMAC verification failed!" << std::endl;
    }
}

int main(int argc, char *argv[]) {
    Time::SetResolution(Time::NS);

    NodeContainer nodes;
    nodes.Create(2);

    PointToPointHelper p2p;
    p2p.SetDeviceAttribute("DataRate", StringValue("1Mbps"));
    p2p.SetChannelAttribute("Delay", StringValue("10ms"));

    NetDeviceContainer devices = p2p.Install(nodes);
    InternetStackHelper stack;
    stack.Install(nodes);

    Ipv4AddressHelper address;
    address.SetBase("10.1.1.0", "255.255.255.0");
    Ipv4InterfaceContainer interfaces = address.Assign(devices);

    // Create sockets
    TypeId tid = TypeId::LookupByName("ns3::UdpSocketFactory");
    Ptr<Socket> recvSocket = Socket::CreateSocket(nodes.Get(1), tid);
    InetSocketAddress local = InetSocketAddress(Ipv4Address::GetAny(), 9);
    recvSocket->Bind(local);
    recvSocket->SetRecvCallback(MakeCallback(&ReceivePacket));

    Ptr<Socket> source = Socket::CreateSocket(nodes.Get(0), tid);
    InetSocketAddress remote = InetSocketAddress(interfaces.GetAddress(1), 9);
    source->Connect(remote);

    // Simulated data + keys
    std::string aesKey = "securekey";
    std::string hmacKey = "hmackey";
    std::string data = "123456";

    Simulator::Schedule(Seconds(1.0), [&] {
        std::string encrypted = EncryptAES(data, aesKey);
        std::string hmac = ComputeHMAC(encrypted, hmacKey);
        std::string fullPacket = encrypted + ":" + hmac;

        Ptr<Packet> packet = Create<Packet>((uint8_t*) fullPacket.c_str(), fullPacket.size());
        source->Send(packet);
        std::cout << "[Node 0] 🚀 Sent encrypted message with HMAC: " << fullPacket << std::endl;
    });

    Simulator::Stop(Seconds(3.0));
    Simulator::Run();
    Simulator::Destroy();

    return 0;
}
