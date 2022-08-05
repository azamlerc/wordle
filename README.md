# wordle
A wordle solver in Swift.

## Usage
Run the script using command line arguments such as:

`Wordle stone:00000 guppy:12001`

* 0 for a letter that was not found (gray)
* 1 for a letter in the wrong place (yellow)
* 2 for a letter in the right place (green)

The program will output a list of possible words given these constraints. Words are sorted based on the frequency of the guessed letters. 
