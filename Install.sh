# Update the package index
apt-get update &&

# Install required packages
apt-get install -y ca-certificates curl gnupg &&

# Create a directory for the Docker GPG key
install -m 0755 -d /etc/apt/keyrings &&

# Download and add the Docker GPG key
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg &&

# Make the Docker GPG key readable to all users
chmod a+r /etc/apt/keyrings/docker.gpg &&

# Add the Docker repository to the APT sources
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null &&

# Update the package index again with the new repository added
apt-get update &&

# Install Docker, Docker CLI, containerd, and plugins
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin &&

# Enable Docker service to start on boot
systemctl enable docker.service &&

# Enable containerd service to start on boot
systemctl enable containerd.service &&

# Create a directory for Docker data and configuration
mkdir -p /home/$USER/docker/data &&

# Run Portainer Docker management tool as a container
docker run -d \
  -p 9443:9443 \
  --name portainer \
  --restart=unless-stopped \
  -v /home/docker/portainer/data/:/data \
  -v /var/run/docker.sock:/var/run/docker.sock \
  portainer/portainer-ce:latest

# Run Sonarr in a Docker container
docker run -d \
  --name sonarr \
  -p 8989:8989 \
  -e PUID=1000 \
  -e PGID=1000 \
  -e UMASK=002 \
  -e TZ="Australia/Perth" \
  -v /home/$USER/docker/sonarr/:/config \
  -v /home/docker/data/:/data \
  ghcr.io/hotio/sonarr:nightly \
  --restart=unless-stopped &&

# Run Radarr in a Docker container
docker run -d \
  --name radarr \
  -p 7878:7878 \
  -e PUID=1000 \
  -e PGID=1000 \
  -e UMASK=002 \
  -e TZ="Australia/Perth" \
  -v /home/$USER/docker/radarr/:/config \
  -v /home/docker/data/:/data \
  ghcr.io/hotio/radarr \
  --restart=unless-stopped &&

# Run Prowlarr in a Docker container
docker run -d \
  --name prowlarr \
  -p 9696:9696 \
  -e PUID=1000 \
  -e PGID=1000 \
  -e UMASK=002 \
  -e TZ="Australia/Perth" \
  -v /home/$USER/docker/prowlarr/:/config \
  -v /home/docker/data/:/data \
  ghcr.io/hotio/prowlarr \
  --restart=unless-stopped &&


apt-get install ufw &&


# Create NFS Share
apt-get update && apt-get install -y nfs-kernel-server &&
echo "/home/$USER/docker/ *(rw,sync,no_subtree_check,no_root_squash,insecure)" >> /etc/exports &&
systemctl restart nfs-kernel-server &&
/usr/sbin/ufw allow ssh &&
/usr/sbin/ufw enable &&
/usr/sbin/ufw allow from 192.168.0.0/24 to any port 2049 &&
/usr/sbin/ufw status verbose &&
chmod 777 /home/$USER/docker/ &&
