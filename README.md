# eth-video-grabber
Download all ETH lecture recordings you have access to.

Disclaimer: Bad code and tested only on Ubuntu 18.04

## Installation
 - Install Ruby
 - Install the gems `faraday` and `down`
 - Rename `lectures.json.example` to `lectures.json` and configure your lectures (see section below)
 - Rename `config.yaml.example` to `config.yaml` and configure it (see section below)
 
## Configuration
In your `lectures.json` file, you have to provide the following information for each of your lectures:
 - `"base"`: The top level link on `https://video.ethz.ch` of the lecture you wish to download without the `.html`. Example: `"https://video.ethz.ch/lectures/d-math/2020/spring/401-0212-16L"`
 - `"course"`: The name of this lecture (only used for the save location). Example: `"Analysis I bei Özlem"`
 - (If access is restricted) `"username"` and `"password"`. 
 
Edit your `config.yaml` file to contain the location you wish to download the lectures to.    
Example: `download_dir: /home/user/eth/videos/` in `config.yaml` with above `lectures.json` would result in Analysis I lectures being downloaded to `/home/user/eth/videos/d-math/2020/spring/Analysis I bei Özlem/`.


## Usage
 - Set up a service to run `ruby grabber.rb` every so often.
 - Enjoy all your lectures in your configured download directory.
