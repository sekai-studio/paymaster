<div align="center">
  <h1>Paymaster Protocol</h1>
</div>

<div align="center">
<br />
</div>

<details>
<summary>Table of Contents</summary>

- [About](#about)
- [Features](#features)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
- [Usage](#usage)
  - [Build](#build)
  - [Run](#run)
  - [Test](#test)
- [Support](#support)
- [Project assistance](#project-assistance)
- [Contributing](#contributing)
- [Authors \& contributors](#authors--contributors)
- [Security](#security)
- [License](#license)
- [Acknowledgements](#acknowledgements)

</details>

---

## About

Paymaster Protocol is a library designed to provide a standard for achieving sponsored transactions on StarkNet.

## Features

A sponsored transaction is a transaction for which the gas fees are not paid by the person executing it but by another person/organism, the *payer*.

Here, we have designed a **PayableAccount** contract that can execute call(s) that are already paid.
The sponsored transactions are sent to the classic *_execute_* endpoint of the payer account contract (classic OZ Account implementation here). The payer forwards the calldata, along with the user's signature, to the *executePaid* endpoint of the user account contract (**PayableAccount** implementation).

This endpoint recomputes the transaction hash of the original user transaction and checks it against the provided signature.

The Cairo part of the repo consists of the **PayableAccount** implementation.
The Python part offers a library to generate/sign/invoke sponsored transactions in a easy way.

There are some examples provided in the *examples* folder.

## Getting Started

### Prerequisites

- [Cairo](https://github.com/starkware-libs/cairo)
- [Protostar](https://github.com/software-mansion/protostar)
- [Python](https://www.python.org/downloads/)

### Installation

Paymaster Protocol is a Protostar package, which can be installed by checking out the `protostar.toml` file as well as the `.gitmodules` file.

## Usage


### Build

Cairo contracts are built using Protostar :
```bash
protostar build
```

### Run

Examples in the *examples* folder can be run as stand-alone Python scripts.

### Test

Unit tests are written in Cairo using Protostar : 
```bash
protostar test
```

Integration tests are written in Python using Pytest & Nile :
```bash
python -m pytest tests/ --disable-pytest-warnings
```

## Support

Reach out to the maintainer at one of the following places:

- [GitHub Discussions](https://github.com/sekai-studio/paymaster/discussions)

## Project assistance

If you want to say **thank you** or/and support active development of this protocol:

- Add a [GitHub Star](https://github.com/sekai-studio/paymaster/discussions) to the project.
- Tweet about this repository.
- Write interesting articles about the project on [Dev.to](https://dev.to/), [Medium](https://medium.com/) or your personal blog.

## Contributing

First off, thanks for taking the time to contribute! Any contributions you make will benefit everybody else and are **greatly appreciated**.

Please read [our contribution guidelines](docs/CONTRIBUTING.md), and thank you for being involved!

## Authors & contributors

For a full list of all authors and contributors, see [the contributors page](https://github.com/sekai-studio/paymaster/graphs/contributors).

## Security

This repository follows good practices of security, but 100% security cannot be assured.
This repository is provided **"as is"** without any **warranty**. Use at your own risk.

_For more information and to report security issues, please refer to our [security documentation](docs/SECURITY.md)._

## License

This project is licensed under the **MIT license**.

See [LICENSE](LICENSE) for more information.

## Acknowledgements

- [OpenZeppelin](https://github.com/OpenZeppelin/cairo-contracts) for the contracts and the tests that are used in this repository.
- [Quaireaux](https://github.com/keep-starknet-strange/quaireaux) for inspiration the open-source side of this repository.

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors) specification. Contributions of any kind welcome!
