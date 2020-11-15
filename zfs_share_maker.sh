#!/usr/bin/env bash
set -euo pipefail

# ZFS Share Maker
## Create a share based on command-line arguments

## SETUP VARIABLES
$SHARE="${1}" # TODO: could be $1
$NETWORK_SOURCE="${2}" # TODO: careful with globbing
$ROOT_POOL= "${3:=rpool}" # TODO: could be default (rpool, change if needed!) OR $3

function init_share () {
# Create ZFS Filesystem
  ## Note the case sensitivity setting and xattr are required for samba and/or nfs
  ## installs, but not nfs-only
  zfs create \
   -o casesensitivity=mixed \
   -o xattr=sa \
   -o dnodesize=auto "${ROOT_POOL}"/"${SHARE}"

  ## Set the Mountpoint - Add `/mnt/` if you don't want these in root... 
  zfs set mountpoint=/"${SHARE}" "${ROOT_POOL}"/"${SHARE}"

  ## Turn on the share for this filesystem
  zfs share "${ROOT_POOL}"/"${SHARE}"
}

function nfs () {
  # Turn on NFS Sharing for the ZFS Filesystem
  ## Optionally Install NFS Prerequisites
  apt install -y nfs-kernel-server 

  ## Set up NFS Firewall Rules
  ufw allow from "${SOURCE_ADDR}" to any port 111,2049 

  ## Turn on NFS Sharing
  zfs set sharenfs=on "${ROOT_POOL}"/"${SHARE}"

  ## Allow Read and Write Operations from the Network Soure for the Share
  zfs set sharenfs="rw=@${SOURCE_ADDR}" "${ROOT_POOL}"/"${SHARE}"
}

function smb () {
  # Turn on Samba/smb/cifs Sharing for the ZFS Filesystem
  ## Optionally Install Samba Prerequisites
  apt install -y samba smbclient

  ## Set up Samba Firewall Rules
  ufw allow proto udp from "${SOURCE_ADDR}" to any port 137,138,139,445
  
  ## Turn on Samba Sharing
  zfs set sharesmb=on "${ROOT_POOL}"/"${SHARE}"

  ## Optionally ensure you have an SMB password for current user
  #smbpasswd -a ${USER} 
}

## SETUP FILESERVER
init_share
smb
#nfs # Uncomment if you want NFS!
