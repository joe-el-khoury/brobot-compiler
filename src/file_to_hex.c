#include <stdio.h>
#include <stdlib.h>

// The default name of the hex delimited file we will be
// writing to.
#define FILE_TO_WRITE_NAME "temp.ioe"
// The number of bytes each word is. We will be going through the
// file in chunks of this constant.
#define WORD_SIZE 4

void write_to_file (FILE*, char*, int);
void zero_terminate_file (FILE*);

void write_to_file (FILE* file_to_write, char* str_to_write, int str_size) {
	if (!file_to_write) return;
	if (!str_to_write) return;

	for (int i = 0; i < str_size; i++) {
		// Write the character in hex with a pipe in front of it.
		fprintf(file_to_write, "|%x", str_to_write[i]);
	}
}

void zero_terminate_file (FILE* file_to_write) {
	if (!file_to_write) return;

	// Write the null character to the end of the file.
	fprintf(file_to_write, "|%x|", '\0');
}

int main (int argc, const char* argv[]) {
	if (argc == 1 || !argv) {
		printf("ioe-compile: fatal error: no input files\n");
		printf("compilation terminated.\n");
		return 1;
	
	} else {
		// Get the file name from the command line arguments.
		const char* file_to_read_name  = argv[1];
		
		// Open the file for reading.
		FILE* file_to_read = fopen(file_to_read_name, "r");
		if (!file_to_read) {
			// Print the errors if the file does not exist.
			printf("ioe-compile: error: %s: No such file or directory\n", file_to_read_name);
			printf("ioe-compile: fatal error: no input files\n");
			printf("compilation terminated.\n");
			return 1;
		}

		// The file is ready for "compilation".
		// Basically we are writing a pipe (|) delimited hex file, based
		// on the hex representations of each character of the file.

		// The file we will write to.
		FILE* file_to_write = fopen(FILE_TO_WRITE_NAME, "w");
		// The current character in the file.
		char read_char;
		// The word of size that is dictated by the constant above.
		char* word = (char*)(malloc(sizeof(char) * WORD_SIZE));;
		int word_index = 0;
		while ( (read_char = fgetc(file_to_read)) != EOF ) {
			if (word_index > WORD_SIZE-1) {
				// The word is now of full size, so we can write to the
				// file in the specified format.
				write_to_file(file_to_write, word, word_index);

				// Don't forget to reset the index!
				word_index = 0;
			}

			printf("%x\n", read_char);

			// Write to the word.
			word[word_index++] = read_char;
		}

		// Trim the string to the correct size, to make sure
		// there are no "leftovers" from the while loop above.
		for (int i = word_index; i < WORD_SIZE; i++) {
			word[word_index] = '\0';
		}
		// Write the rest of the stuff to the string.
		write_to_file(file_to_write, word, word_index);
		free(word);

		zero_terminate_file(file_to_write);

		// Close all the files we ever opened.
		fclose(file_to_read);
		fclose(file_to_write);

	}

	return 0;
}