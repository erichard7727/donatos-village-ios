# Tooling

* Xcode 11.5

What things you need to install the software and how to install them

- [Homebrew](#) (see .brewfile for things this will install)
- [Ruby](#) (recommending at least version 2.4)
- [rbenv](#) (_optional_, is great for managing ruby environments and associated gems)
- [Bundler](#) (for installing Ruby gems)
- [Cocoapods](#) (for dependency management)
- [Fastlane](#) (for deployment automations)

### Installing

First follow the [instructions to install Homebrew](#).

Then, use it to install the prerequisites.

	$ brew bundle

At this point, [rbenv](#) should be installed and you should make sure it is running the version specified in the _.ruby-version_ file of this project.

	$ ruby --version

Next, install [Bundler](#).

	$ gem install bundler
	$ rbenv rehash

And then use Bundler to install the required gems (see .gemfile for the list)[^1]

	$ bundle install
	$ rbenv rehash

Next, use Cocoapods to make sure dependencies are installed

	$ bundle exec pod install

You should now have everything you need to get working. If not, please figure out what went wrong and then update these instructions accordingly. :)

	$ open Village.xcworkspace
