Release Process
====================


###update (commit) version in sources

	contrib/verifysfbinaries/verify.sh
	doc/README*
	share/setup.nsi
	src/clientversion.h (change CLIENT_VERSION_IS_RELEASE to true)
	./configure.ac (change (_CLIENT_VERSION_IS_RELEASE, true))

###tag version in git

	git tag -s v(new version, e.g. 0.8.0)

###write release notes. git shortlog helps a lot, for example:

	git shortlog --no-merges v(current version, e.g. 0.7.2)..v(new version, e.g. 0.8.0)
	or alternatively
	git log --no-merges --abbrev=7 --date=short --pretty=format:"- \`%h\` %s  " v(current version, e.g. 1.4.1)..v(new version, e.g. 2.0.0) > git.log


* * *

###update gitian

 In order to take advantage of the new caching features in gitian, be sure to update to a recent version (fa0f0f4e5 is recommended)

###perform gitian builds

 From a directory containing the Cashera source, gitian-builder and gitian.sigs
  
	export SIGNER=(your gitian key, ie bluematt, sipa, etc)
	export VERSION=(new version, e.g. 0.8.0)
	pushd ./Cashera
	git checkout v${VERSION}
	popd
	pushd ./gitian-builder

###fetch and build inputs: (first time, or when dependency versions change)
 
	mkdir -p inputs

 Register and download the Apple SDK: (see OSX Readme for details)
 
 https://developer.apple.com/downloads/download.action?path=Developer_Tools/xcode_6.1.1/xcode_6.1.1.dmg
 
 Using a Mac, create a tarball for the 10.9 SDK and copy it to the inputs directory:
 
	tar -C /Volumes/Xcode/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/ -czf MacOSX10.9.sdk.tar.gz MacOSX10.9.sdk

###Optional: Seed the Gitian sources cache

  By default, gitian will fetch source files as needed. For offline builds, they can be fetched ahead of time:

	make -C ../bitcoin/depends download SOURCES_PATH=`pwd`/cache/common

  Only missing files will be fetched, so this is safe to re-run for each build.

###Build Cashera Core for Linux, Windows, and OS X:
  
	./bin/gbuild --commit Cashera=v${VERSION} ../bitcoin/contrib/gitian-descriptors/gitian-linux.yml
	./bin/gsign --signer $SIGNER --release ${VERSION}-linux --destination ../gitian.sigs/ ../Cashera/contrib/gitian-descriptors/gitian-linux.yml
	mv build/out/Cashera-*.tar.gz build/out/src/bitcoin-*.tar.gz ../
	./bin/gbuild --commit Cashera=v${VERSION} ../bitcoin/contrib/gitian-descriptors/gitian-win.yml
	./bin/gsign --signer $SIGNER --release ${VERSION}-win --destination ../gitian.sigs/ ../Cashera/contrib/gitian-descriptors/gitian-win.yml
	mv build/out/Cashera-*.zip build/out/bitcoin-*.exe ../
	./bin/gbuild --commit Cashera=v${VERSION} ../bitcoin/contrib/gitian-descriptors/gitian-osx.yml
	./bin/gsign --signer $SIGNER --release ${VERSION}-osx-unsigned --destination ../gitian.sigs/ ../Cashera/contrib/gitian-descriptors/gitian-osx.yml
	mv build/out/Cashera-*-unsigned.tar.gz inputs
	mv build/out/Cashera-*.tar.gz build/out/Cashera-*.dmg ../
	popd
  Build output expected:

  1. source tarball (Cashera-${VERSION}.tar.gz)
  2. linux 32-bit and 64-bit binaries dist tarballs (Cashera-${VERSION}-linux[32|64].tar.gz)
  3. windows 32-bit and 64-bit installers and dist zips (Cashera-${VERSION}-win[32|64]-setup.exe, bitcoin-${VERSION}-win[32|64].zip)
  4. OSX unsigned installer (Cashera-${VERSION}-osx-unsigned.dmg)
  5. Gitian signatures (in gitian.sigs/${VERSION}-<linux|win|osx-unsigned>/(your gitian key)/

###Next steps:

Commit your signature to gitian.sigs:

	pushd gitian.sigs
	git add ${VERSION}-linux/${SIGNER}
	git add ${VERSION}-win/${SIGNER}
	git add ${VERSION}-osx-unsigned/${SIGNER}
	git commit -a
	git push  # Assuming you can push to the gitian.sigs tree
	popd

  Wait for OSX detached signature:
	Once the OSX build has 3 matching signatures, John will sign it with the apple App-Store key.
	He will then upload a detached signature to be combined with the unsigned app to create a signed binary.

  Create the signed OSX binary:

	pushd ./gitian-builder
	# Fetch the signature as instructed by John
	cp signature.tar.gz inputs/
	./bin/gbuild -i ../Cashera/contrib/gitian-descriptors/gitian-osx-signer.yml
	./bin/gsign --signer $SIGNER --release ${VERSION}-osx-signed --destination ../gitian.sigs/ ../Cashera/contrib/gitian-descriptors/gitian-osx-signer.yml
	mv build/out/Cashera-${VERSION}-osx.dmg ../
	popd

Commit your signature for the signed OSX binary:

	pushd gitian.sigs
	git add ${VERSION}-osx-signed/${SIGNER}
	git commit -a
	git push  # Assuming you can push to the gitian.sigs tree
	popd

-------------------------------------------------------------------------

### After 3 or more people have gitian-built and their results match:

- Perform code-signing.

    - Code-sign Windows -setup.exe (in a Windows virtual machine using signtool)

  Note: only John has the code-signing keys currently.

- Create `SHA256SUMS.asc` for the builds, and GPG-sign it:
```bash
sha256sum * > SHA256SUMS
gpg --digest-algo sha256 --clearsign SHA256SUMS # outputs SHA256SUMS.asc
rm SHA256SUMS
```
(the digest algorithm is forced to sha256 to avoid confusion of the `Hash:` header that GPG adds with the SHA256 used for the files)

- Upload zips and installers, as well as `SHA256SUMS.asc` from last step, to github release

- Update Cashera.com version
- Upload gitian zips to github releases

- Announce the release:

  - Release sticky on Casheratalk: https://www.Casheratalk.org/category/1/announcements

  - Reddheads mailing list

  - Update title of #Cashera on Freenode IRC

  - Reddit /r/Cashera,

- Add release notes for the new version to the directory `doc/release-notes` in git master

- Celebrate 
