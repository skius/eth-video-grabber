# eth-video-grabber
Download all [ETHZ](https://ethz.ch) lecture recordings you have access to.

## Installation
 - Install Ruby
 - Install the gems `faraday` and `down` (`$ gem install faraday down`)
 - Rename `lectures.json.example` to `lectures.json` and configure your lectures (see section below)
 - Rename `config.yaml.example` to `config.yaml` and configure it (see section below)
 
## Configuration
#### lectures.json
In your `lectures.json` file, you have to provide the following information for each of your lectures (as array):
 - `"base"`: The top level link on `https://video.ethz.ch` of the lecture you wish to download without the `.html`. 
 Example: `"https://video.ethz.ch/lectures/d-math/2020/spring/401-0212-16L"`
 - `"course"`: The name of this lecture (only used for the save location). Example: `"Analysis I bei Özlem"`
 - (Optional) `"username"` and `"password"`: Either your ETHZ LDAP account or a lecture login, 
 whichever applies. 
 - (Optional) `"ldap"`: if the recordings are protected with your ETHZ LDAP account, set this to true.
 
Example:
 
```json
[
  {
    "username": "lecture_username",
    "password": "lecture_password",
    "base": "https://video.ethz.ch/lectures/d-math/2020/spring/401-0212-16L",
    "course": "Analysis I bei Özlem"
  },
  {
    "username": "ethz_username",
    "password": "ethz_password",
    "ldap": true,
    "base": "https://video.ethz.ch/lectures/d-infk/2020/spring/252-0030-00L",
    "course": "A und W"
  },
  {
    "base": "https://video.ethz.ch/lectures/d-infk/2020/spring/252-0028-00L",
    "course": "Digital Design and Computer Architecture"
  }
]
```
 
#### config.yaml
 
Edit your `config.yaml` file to contain the location you wish to download the lectures to (without a trailing slash).    
Example: 

```
download_dir: /home/user/eth/videos
``` 

 in `config.yaml` with above `lectures.json` would result in Analysis I lectures being downloaded to `/home/user/eth/videos/d-math/2020/spring/Analysis I bei Özlem/`.


## Usage
 - Set up a service to run `ruby grabber.rb` every so often.
 - Enjoy all your lectures in the configured download directory.
