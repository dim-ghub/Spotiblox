# Spotiblox

Automatically update your Roblox "About Me" section containing information of the currently playing song on Spotify.

## What It Does

Spotiblox is a bash script that monitors your Spotify playback and automatically updates your Roblox profile's "About Me" section with real-time song information. When you play music on Spotify, your Roblox profile will display:

- Current song title and artist
- Play/pause status with visual indicators (⏸ for playing, ▶ for paused)
- Current position and duration (updates in real-time when playing)
- Media control symbols (⏮ ⏸ ⏭)
- Automatic profanity filtering
- Clears the About Me section when Spotify is closed

## How It Works

The script works by:

1. **Monitoring Spotify**: Uses `playerctl` to detect Spotify and retrieve metadata (title, artist, status, position, duration)
2. **Processing Data**: Truncates long strings, applies profanity filtering, and formats the display
3. **Roblox API Communication**: Uses Python to make authenticated requests to Roblox's API to update the profile description
4. **Real-time Updates**: Continuously monitors for changes and updates the profile immediately when songs change
5. **Smart Position Tracking**: Updates timestamp every 10 seconds when playing, instantly when paused

## Requirements

### System Dependencies
- **Linux system** with `playerctl` installed
- **Python 3** with `requests` library
- **Base64** utility (usually pre-installed)
- **Bash** shell

### Installation Commands

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install playerctl python3 python3-pip
pip3 install requests
```

**Fedora/CentOS:**
```bash
sudo dnf install playerctl python3 python3-pip
pip3 install requests
```

**Arch Linux:**
```bash
sudo pacman -S playerctl python python-pip
pip install requests
```

### Spotify Setup
- Spotify must be running and accessible via `playerctl`
- Works with Spotify desktop application on Linux
- Ensure Spotify is installed and logged in to your account

## Setup Instructions

1. **Clone the repository:**
```bash
git clone https://github.com/dim-ghub/Spotiblox.git
cd Spotiblox
```

2. **Make the script executable:**
```bash
chmod +x spotiblox.sh
```

3. **Run the script:**
```bash
./spotiblox.sh
```

4. **First-time setup:**
   - The script will prompt for your `.ROBLOSECURITY` cookie
   - Enter your Roblox cookie when prompted
   - The cookie will be securely stored in `~/.spotiblox` (base64 encoded, 600 permissions)

### Finding Your .ROBLOSECURITY Cookie

1. Log in to Roblox in your browser
2. Open browser developer tools (F12)
3. Go to the **Application** tab (Chrome) or **Storage** tab (Firefox)
4. Navigate to **Cookies** → **https://www.roblox.com**
5. Find the `.ROBLOSECURITY` cookie and copy its value

## Usage

- Run `./spotiblox.sh` in a terminal
- Keep the script running while you want automatic updates
- Press `Ctrl+C` to stop the script
- The script will automatically:
  - Update your profile when songs change
  - Clear your profile when Spotify is closed
  - Handle play/pause states appropriately

## Security Considerations

- Your `.ROBLOSECURITY` cookie is stored locally in `~/.spotiblox`
- The file has restricted permissions (600) for security
- The cookie is base64 encoded to prevent accidental exposure
- Never share your `.ROBLOSECURITY` cookie with anyone

## Configuration

You can modify these variables in the script:
- `MAX_TITLE_LEN`: Maximum title length (default: 300)
- `MAX_ARTIST_LEN`: Maximum artist length (default: 300)
- `CONFIG_FILE`: Location of the cookie storage file

## Troubleshooting

**Script can't find Spotify:**
- Ensure Spotify is running and playing music
- Check that `playerctl -l` shows spotify in the list
- Verify Spotify integration is enabled in your system

**Python requests not found:**
- Install with: `pip3 install requests`

**Permission denied:**
- Make script executable: `chmod +x spotiblox.sh`
- Check file permissions

**Cookie issues:**
- Remove `~/.spotiblox` file and re-run the script
- Ensure you're copying the complete cookie value

## License

This project is licensed under the terms specified in the LICENSE file.
