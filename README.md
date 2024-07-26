
[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![GPL3 License][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url]
[![Ask Me Anything][ask-me-anything]][personal-page]

<!-- PROJECT LOGO -->
<br />
<p align="center">
  <a href="https://github.com/stiliajohny/historikeeper">
    <img src="https://raw.githubusercontent.com/stiliajohny/historikeeper/main/.assets/logo.png" alt="Main Logo" width="80" height="80">
  </a>

  <h3 align="center">historikeeper</h3>

  <p align="center">
    A ZSH plugin that captures history in a database
    <br />
    <a href="./README.md"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://github.com/stiliajohny/historikeeper/issues/new?labels=i%3A+bug&template=1-bug-report.md">Report Bug</a>
    ·
    <a href="https://github.com/stiliajohny/historikeeper/issues/new?labels=i%3A+enhancement&template=2-feature-request.md">Request Feature</a>
  </p>
</p>

<!-- TABLE OF CONTENTS -->

## Table of Contents

- [Table of Contents](#table-of-contents)
- [About The Project](#about-the-project)
  - [Built With](#built-with)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
- [Usage](#usage)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)
- [Acknowledgements](#acknowledgements)

<!-- ABOUT THE PROJECT -->

## About The Project

[![historikeeper Screen Shot][product-screenshot]](./.assets/screenshot.png)

### Built With

- [Zsh](https://www.zsh.org)
- [PostgreSQL](https://www.postgresql.org)
- [Docker](https://www.docker.com)
- [Python](https://www.python.org)

---

<!-- GETTING STARTED -->

## Getting Started

### Prerequisites

- Docker
- PostgreSQL client (optional, for manual access to the database)
- Python 3.6+ 
- `pip` (Python package installer)

### Installation

1. **Clone the repo**

   ```sh
   git clone https://github.com/stiliajohny/historikeeper.git $ZSH_CUSTOM/plugins/historikeeper
   ```

2. **Deploy PostgreSQL with Docker**

   ```sh
   docker pull postgres
   docker run --name postgres-db -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=mysecretpassword -e POSTGRES_DB=histori_keeper -p 5432:5432 -d postgres
   ```

3. **Install Python dependencies**

   ```sh
   pip install -r $ZSH_CUSTOM/plugins/historikeeper/requirements.txt
   ```

4. **Add the plugin to your .zshrc configuration**

   ```sh
   plugins=(... historikeeper)
   ```

5. **Set variables in your .zshrc**

   ```sh
   HISTORIKEEPER_PRINT_DETAILS=true
   HISTORIKEEPER_LOGTOPOSTGRES=true
   ```

6. **Source your .zshrc to apply the changes**

   ```sh
   source ~/.zshrc
   ```

---

## Usage

### Import existing history 

1. CD in the plugin folder 
   ```bash
   cd $ZSH_CUSTOM/plugins/historikeeper/
   ```
1. run the import command 
   ```bash 
   python3 ./parse_zsh_history.py -vvvv --input-file ~/.zsh_history --pg-host localhost --pg-port 5432 --pg-user postgres --pg-password mysecretpassword --pg-db histori_keeper
   ```

### Normal Plugin Usage
The plugin captures each command run in your terminal and logs it to the PostgreSQL database if `HISTORIKEEPER_LOGTOPOSTGRES` is set to `true`. 

You can view the details of the last command executed directly in your terminal if `HISTORIKEEPER_PRINT_DETAILS` is set to `true`.

Example of what is captured:
```shell
johnstilia in ~/.config/oh-my-zsh/custom/plugins/historikeeper on master ● ● λ ls
HistoriKeeper.plugin.zsh LICENSE.txt              README.md                _config.yml
>--------------------------------------------------
Last Command Details:
Epoch Timestamp: 1721927239
Timestamp: 2024-07-25T18:07:19+0100
Command: ls
Command Arguments:
Exit Code: 0
Execution Time (milliseconds): 12
Hostname: Johns-MacBook-Pro.local
Username: johnstilia
Output:
HistoriKeeper.plugin.zsh
LICENSE.txt
README.md
_config.yml
IP Address: Johns-MacBook-Pro.local
PPID: 58531
TTY: /dev/ttys055
Working Directory: /Users/johnstilia/.config/oh-my-zsh/custom/plugins/historikeeper
Shell Type: /bin/zsh
Session Start Time: 2024-07-25T18:07:17+0100
Public IP Address: 152.37.89.249
Public Hostname: 89.37.152.249.bcube.co.uk
>--------------------------------------------------
Toggling Variables:
HISTORIKEEPER_PRINT_DETAILS: true
HISTORIKEEPER_LOGTOPOSTGRES: true
>--------------------------------------------------
```

---

## Roadmap

See the [open issues](https://github.com/stiliajohny/historikeeper/issues) for a list of proposed features (and known issues).

---

## Contributing

Contributions are what make the open source community such an amazing place to be learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## License

Distributed under the GPLv3 License. See `LICENSE` for more information.

## Contact

John Stilia - stilia.johny@gmail.com

---

## Acknowledgements

- [GitHub Emoji Cheat Sheet](https://www.webpagefx.com/tools/emoji-cheat-sheet)
- [Img Shields](https://shields.io)
- [Choose an Open Source License](https://choosealicense.com)
- [GitHub Pages](https://pages.github.com)

<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->

[contributors-shield]: https://img.shields.io/github/contributors/stiliajohny/historikeeper.svg?style=for-the-badge
[contributors-url]: https://github.com/stiliajohny/historikeeper/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/stiliajohny/historikeeper.svg?style=for-the-badge
[forks-url]: https://github.com/stiliajohny/historikeeper/network/members
[stars-shield]: https://img.shields.io/github/stars/stiliajohny/historikeeper.svg?style=for-the-badge
[stars-url]: https://github.com/stiliajohny/historikeeper/stargazers
[issues-shield]: https://img.shields.io/github/issues/stiliajohny/historikeeper.svg?style=for-the-badge
[issues-url]: https://github.com/stiliajohny/historikeeper/issues
[license-shield]: https://img.shields.io/github/license/stiliajohny/historikeeper?style=for-the-badge
[license-url]: https://github.com/stiliajohny/historikeeper/blob/master/LICENSE.txt
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://linkedin.com/in/john.stilia/
[product-screenshot]: .assets/screenshot.png
[ask-me-anything]: https://img.shields.io/badge/Ask%20me-anything-1abc9c.svg?style=for-the-badge
[personal-page]: https://github.com/stiliajohny
