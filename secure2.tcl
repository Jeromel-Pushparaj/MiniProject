#!/usr/bin/env tclsh

# === Utility ===
proc print_section {msg} {
    puts "\n======================================="
    puts "🔷 $msg"
    puts "=======================================\n"
}

# === Generate RSA keys ===
proc generate_rsa_keys {nodeName} {
    set privateKey "${nodeName}-private.pem"
    set publicKey "${nodeName}-public.pem"
    print_section "Generating RSA Key Pair for $nodeName"
    if {[catch {
        exec openssl genpkey -algorithm RSA -out $privateKey -pkeyopt rsa_keygen_bits:2048 2>@1
        exec openssl rsa -in $privateKey -pubout -out $publicKey 2>@1
    } err]} {
        puts "❌ Error generating RSA keys for $nodeName:\n$err"
        return 0
    } else {
        puts "✅ RSA private key: $privateKey"
        puts "✅ RSA public key : $publicKey"
        return 1
    }
}

# === Generate AES key ===
proc generate_aes_key {file} {
    print_section "Generating AES Key"
    if {[catch {
        exec openssl rand -hex 32 > $file
    } err]} {
        puts "❌ Failed to generate AES key:\n$err"
        return 0
    } else {
        puts "✅ AES key saved to $file"
        return 1
    }
}

# === Encrypt AES key using RSA ===
proc rsa_encrypt {publicKeyFile inputFile outputFile} {
    print_section "Encrypting AES Key with Node B's Public Key"
    if {[catch {
        exec openssl pkeyutl -encrypt -pubin -inkey $publicKeyFile -in $inputFile -out $outputFile
    } err]} {
        puts "❌ RSA encryption failed:\n$err"
        return 0
    } else {
        puts "✅ AES key encrypted and saved to $outputFile"
        return 1
    }
}

# === Secure Setup ===
print_section "Starting Secure Communication Setup"

set okA [generate_rsa_keys "nodeA"]
set okB [generate_rsa_keys "nodeB"]

if {!$okA || !$okB} {
    puts "\n❌ Aborting due to key generation failure."
    exit 1
}

set aesKeyFile "aes.key"
if {![generate_aes_key $aesKeyFile]} {
    puts "\n❌ Aborting due to AES key generation failure."
    exit 1
}

set encKeyFile "aes_encrypted.key"
if {![rsa_encrypt "nodeB-public.pem" $aesKeyFile $encKeyFile]} {
    puts "\n❌ Aborting due to encryption failure."
    exit 1
}

# === Simulation & Visualization ===
print_section "🔒 Visualization of Key Exchange"

puts "🧩 Node A:"
puts "  - Has RSA Key Pair (nodeA-private.pem, nodeA-public.pem)"
puts "  - Generates AES Key → ${aesKeyFile}"
puts "  - Encrypts AES Key using Node B's public key → ${encKeyFile}"

puts "\n🧩 Node B:"
puts "  - Has RSA Key Pair (nodeB-private.pem, nodeB-public.pem)"
puts "  - Can decrypt AES Key using nodeB-private.pem"

puts "\n✅ Secure setup complete!"

# === NS2 Simulation with NAM ===
set ns [new Simulator]

# Open trace and NAM output
set tracefile [open "secure.tr" w]
set namfile [open "secure.nam" w]
$ns trace-all $tracefile
$ns namtrace-all $namfile

# Nodes and link
set nodeA [$ns node]
set nodeB [$ns node]
$ns duplex-link $nodeA $nodeB 1Mb 10ms DropTail

# Agents and traffic
set udp [new Agent/UDP]
set null [new Agent/Null]
$ns attach-agent $nodeA $udp
$ns attach-agent $nodeB $null
$ns connect $udp $null

# CBR Traffic
set cbr [new Application/Traffic/CBR]
$cbr set packetSize_ 512
$cbr set interval_ 0.005
$cbr attach-agent $udp

# Start and stop events
$ns at 1.0 "$cbr start"
$ns at 4.0 "$cbr stop"

# Finish proc
proc finish {} {
    global ns tracefile namfile
    $ns flush-trace
    close $tracefile
    close $namfile
    exec nam secure.nam &
    exit 0
}
$ns at 5.0 "finish"

# Run the simulation
$ns run

