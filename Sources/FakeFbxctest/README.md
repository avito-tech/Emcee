##  What's 'fake fbxctest'?

AvitoRunner currently uses `fbxctest` as an API for running tests. In order to make AvitoRunner's modules testable without actually
bringing an executable of `fbxctest` together with unit tests, there is a fake fbxctest thing.

What it essentially does is it reads the predefined JSON file and prints it's output back to the stdout. 
Unit tests just tell it what it should output and then AvitoRunner will parse the output and behave accordingly.

## Configuring fake fbxctest

You just put a file named `FakeFbxctestExecutableProducer.fakeOutputJsonFilename` next to the fake fbxctest binary.
You can put multiple JSON files with suffixes, it will sort these files and print first available, and then delete it. This allows to
control what fake fbxctest outputs depending on the run iteration. Useful for testing retries and so on.

## How to build fake fbxctest?

This is a swift package manager binary, so just invoke `swift build`/`make build` and it will produce both 
AvitoRunner and fake_fbxctest binaries.
