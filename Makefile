LIBS_FOLDER = "./libs/"

install:
	curl -Ls -o $(LIBS_FOLDER)/JSON.sh --create-dirs https://github.com/dominictarr/JSON.sh/raw/master/JSON.sh
	chmod +x $(LIBS_FOLDER)/*

