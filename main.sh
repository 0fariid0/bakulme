#!/bin/bash

download_and_extract() {
  url=$1
  output=$2
  echo "Downloading $output..."
  wget $url -O $output
  if [[ $? -ne 0 ]]; then
    echo "Error downloading $output."
    exit 1
  fi
  echo "Download of $output completed."

  echo "Extracting $output..."
  tar -xzf $output
  if [[ $? -eq 0 ]]; then
    echo "Extraction of $output completed."
    echo "Removing the ZIP file $output..."
    rm -f $output
    echo "$output removed."
  else
    echo "Error extracting $output."
    exit 1
  fi
}

create_service() {
  service_name=$1
  toml_file=$2

  echo "Creating service for $toml_file..."

  cat <<EOF > /etc/systemd/system/$service_name.service
[Unit]
Description=Backhaul Reverse Tunnel Service - $service_name
After=network.target

[Service]
Type=simple
ExecStart=/root/backhaul -c /root/$toml_file
Restart=always
RestartSec=3
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

  echo "Service $service_name created."

  sudo systemctl daemon-reload
  sudo systemctl enable $service_name.service
  sudo systemctl start $service_name.service
  echo "Service $service_name started."
}

menu() {
  echo "Please select an option:"
  echo "1) Install Core"
  echo "2) Iran"
  echo "3) Abroad"
  echo "4) Full removal"
}

while true; do
  menu
  read -p "Your choice: " choice

  case $choice in
    1)
      echo "Install Core selected."
      if [[ ! -f "/root/backhaul" ]]; then
        download_file "https://github.com/0fariid0/bakulme/raw/main/backhaul" "/root/backhaul"
      else
        echo "Backhaul file already downloaded."
      fi
      ;;
    2)
      echo "Iran selected."
      download_and_extract "https://github.com/0fariid0/bakulme/raw/main/ir.zip" "ir.zip"

      for i in {1..6}; do
        create_service "backhaul-tu$i" "tu$i.toml"
      done
      ;;
    3)
      echo "Abroad selected."
      download_and_extract "https://github.com/0fariid0/bakulme/raw/main/kh.zip" "kh.zip"

      read -p "Enter abroad number (1 to 6): " external_number
      if [[ $external_number =~ ^[1-6]$ ]]; then
        service_name="backhaul-tu$external_number"
        toml_file="tu$external_number.toml"
        create_service $service_name $toml_file
      else
        echo "Invalid number! Please enter a number between 1 and 6."
      fi
      ;;
    4)
      echo "Full removal selected."
      echo "Removing files and services..."

      [[ -f "/root/backhaul" ]] && rm -f /root/backhaul && echo "Backhaul file removed."
      [[ -f "ir.zip" ]] && rm -f ir.zip && echo "ir.zip removed."
      [[ -f "kh.zip" ]] && rm -f kh.zip && echo "kh.zip removed."

      for i in {1..6}; do
        sudo systemctl stop backhaul-tu$i.service
        sudo systemctl disable backhaul-tu$i.service
        rm /etc/systemd/system/backhaul-tu$i.service
        echo "Service backhaul-tu$i removed."
      done

      sudo systemctl daemon-reload
      echo "All files and services removed."
      ;;
    *)
      echo "Invalid choice!"
      ;;
  esac
done
