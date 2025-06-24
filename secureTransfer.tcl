# Secure Data Transfer Simulation in NS2/NAM

# Create simulator instance
set ns [new Simulator]

# Open NAM trace file
set nf [open out.nam w]
$ns namtrace-all $nf

# Define topology
set n0 [$ns node]  ;# Node A (Sender)
set n1 [$ns node]  ;# Node B (Receiver)

# Positioning for NAM
$ns duplex-link $n0 $n1 1Mb 10ms DropTail
$ns duplex-link-op $n0 $n1 orient right

# Monitor queue
$ns duplex-link-op $n0 $n1 queuePos 0.5

# Set up TCP connection
set tcp [new Agent/TCP]
$ns attach-agent $n0 $tcp

set sink [new Agent/TCPSink]
$ns attach-agent $n1 $sink

$ns connect $tcp $sink

# Create an application to send data
set app [new Application/FTP]
$app attach-agent $tcp

# Schedule events
$ns at 0.5 "$app start"
$ns at 1.5 "$app stop"
$ns at 2.0 "finish"

# Finish procedure
proc finish {} {
    global ns nf
    $ns flush-trace
    close $nf
    exec nam out.nam &
    exit 0
}

# Run simulation
$ns run

