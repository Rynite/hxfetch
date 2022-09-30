package;

import ArgumentParser.ArgumentParser;

class Main {
	static function main() {
		HxFetch.print_fetch("archlinux");
		ArgumentParser.register();
		trace(ArgumentParser.color1);
	}
}
