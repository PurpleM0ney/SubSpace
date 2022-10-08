#!/bin/bash

if [ ! $NODE_NAME ]; then
	read -p "Имя вашей ноды : " NODE_NAME
fi
echo 'Имя вашей ноды: ' $NODE_NAME
sleep 1
echo 'export SUBSPACE_NODENAME='$NODE_NAME >> $HOME/.bash_profile
echo -e '\n\e[42mГотово\e[0m\n'
echo "-----------------------------------------------------------------------------"
if [ ! $YOUR_WALLET ]; then
	read -p "Адрес кошелька Subspace Gemini 2: " YOUR_WALLET
fi
echo 'Адрес кошелька: ' $YOUR_WALLET
sleep 1
echo 'export SUBSPACE_WALLET='$YOUR_WALLET >> $HOME/.bash_profile
echo -e '\n\e[42mГотово\e[0m\n'
echo "-----------------------------------------------------------------------------"


exists()
{
  command -v "$1" >/dev/null 2>&1
}
if exists curl; then
	echo ''
else
  sudo apt update && sudo apt install curl -y < "/dev/null"
fi
bash_profile=$HOME/.bash_profile
if [ -f "$bash_profile" ]; then
    . $HOME/.bash_profile
fi
sleep 1

sudo apt update && sudo apt install ocl-icd-opencl-dev libopencl-clang-dev libgomp1 -y
cd $HOME
rm -rf subspace*
wget -O subspace-node https://github.com/subspace/subspace/releases/download/gemini-2a-2022-sep-06/subspace-node-ubuntu-x86_64-gemini-2a-2022-sep-06
wget -O subspace-farmer https://github.com/subspace/subspace/releases/download/gemini-2a-2022-sep-06/subspace-farmer-ubuntu-x86_64-gemini-2a-2022-sep-06
chmod +x subspace*
mv subspace* /usr/local/bin/

systemctl stop subspaced subspaced-farmer &>/dev/null
rm -rf ~/.local/share/subspace*

source ~/.bash_profile
sleep 1

echo "[Unit]
Description=Subspace Node
After=network.target

[Service]
User=$USER
Type=simple
ExecStart=/usr/local/bin/subspace-node --chain gemini-2a --execution wasm --state-pruning archive --validator --name $SUBSPACE_NODENAME
Restart=on-failure
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target" > $HOME/subspaced.service


echo "[Unit]
Description=Subspaced Farm
After=network.target

[Service]
User=$USER
Type=simple
ExecStart=/usr/local/bin/subspace-farmer farm --reward-address $SUBSPACE_WALLET --plot-size 100G
Restart=on-failure
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target" > $HOME/subspaced-farmer.service


mv $HOME/subspaced* /etc/systemd/system/
sudo systemctl restart systemd-journald
sudo systemctl daemon-reload
sudo systemctl enable subspaced subspaced-farmer
sudo systemctl restart subspaced
sleep 10
sudo systemctl restart subspaced-farmer

echo "==================================================="
echo -e '\n\e[42mПроверка статуса ноды\e[0m\n' && sleep 1
if [[ `service subspaced status | grep active` =~ "running" ]]; then
  echo -e "Subspace нода \e[32mустановлен и работает\e[39m!"
  echo -e "Ты можешь проверить работоспособность ноды командой \e[7mservice subspaced status\e[0m"
  echo -e "ажми \e[7mQ\e[0m для выхода из меню"
else
  echo -e "Subspace нода \e[31mбыла установлена некорректно\e[39m, пожалуйста, переустанови ее."
fi
sleep 2
echo "==================================================="
echo -e '\n\e[42mПроверка статуса фармера\e[0m\n' && sleep 1
if [[ `service subspaced-farmer status | grep active` =~ "running" ]]; then
  echo -e "Subspace фармер \e[32mустановлен и работает\e[39m!"
  echo -e "Ты можешь проверить работоспособность фармера командой \e[7mservice subspaced-farmer status\e[0m"
  echo -e "Нажми \e[7mQ\e[0m для выхода из меню"
else
  echo -e "Subspace фармер \e[31mбыл установлен некорректно\e[39m, пожалуйста, переустанови его."
fi