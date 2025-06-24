#!/usr/bin/env tclsh

# === Utility ===
proc print_section {msg} {
    puts "\n======================================="
    puts " $msg"
    puts "=======================================\n"
}

# === AES Key Generation ===
proc generate_aes_key {file} {
    print_section "Generating AES Key"
    
    if {[catch { exec openssl rand -hex 32 > $file } err]} {
        puts " Failed to generate AES key:\n$err"
        return 0
    } else {
        puts " AES key saved to $file"
        return 1
    }
}

# === AES Encrypt Number with PBKDF2 ===
proc aes_encrypt {keyFile inputFile outputFile} {
    print_section "Encrypting Numerical Value with AES Key"
    
    # Use PBKDF2 for key derivation
    if {[catch { exec openssl enc -aes-256-cbc -salt -in $inputFile -out $outputFile -pass file:$keyFile -pbkdf2 } err]} {
        puts " AES encryption failed:\n$err"
        return 0
    } else {
        puts " Encrypted number saved to $outputFile"
        return 1
    }
}

# === AES Decrypt Number with PBKDF2 ===
proc aes_decrypt {keyFile inputFile outputFile} {
    print_section "Decrypting Numerical Value with AES Key"
    
    # Use PBKDF2 for key derivation
    if {[catch { exec openssl enc -d -aes-256-cbc -in $inputFile -out $outputFile -pass file:$keyFile -pbkdf2 } err]} {
        puts " AES decryption failed:\n$err"
        return 0
    } else {
        puts " Decrypted number saved to $outputFile"
        return 1
    }
}

# === Secure Setup ===
print_section "Starting Secure Communication Setup"

# Generate AES key for encryption
set aesKeyFile "aes.key"
if {! [generate_aes_key $aesKeyFile]} {
    puts "\n Aborting due to AES key generation failure."
    exit 1
}

# Encrypt an integer (e.g., 7543) using AES key
set numberValue 7543
set numberFile "number.txt"
set f [open $numberFile w]
puts $f $numberValue
close $f

set encryptedNumber "number.enc"
if {! [aes_encrypt $aesKeyFile $numberFile $encryptedNumber]} {
    puts "\n Aborting due to AES encryption failure."
    exit 1
}

# === Node B Decrypting ===
print_section " Node B Decrypting Received Data"

# Decrypt AES key using Node B's private key (simulate process here)
# In reality, you would decrypt AES key using RSA keys
set decryptedNumber "number_decrypted.txt"
if {! [aes_decrypt $aesKeyFile $encryptedNumber $decryptedNumber]} {
    puts "\n Aborting due to AES decryption failure."
    exit 1
}

# Output decrypted number
set f [open $decryptedNumber r]
set decryptedValue [read $f]
close $f
puts " Decrypted number: $decryptedValue"
