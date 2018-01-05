# Ruby Terminal Projects

This is a very small terminal application used to select from the small projects stored inside this project. All the projects are actually terminal games right now so this application serves as a game selector.

## Usage
To run this program, execute `./game` in the project directory. If the application does not load and display a list of commands you may execute then you may not have execute permission. To fix this, use the terminal command `chmod +x game` and try again. If you are using Windows, the file naming is likely different.

##### Example
```
./game list
```
This will list all the possible choices for the `play` command.

```
./game play GAME_NAME
```
This will load whichever game you have chosen. Replace `GAME_NAME` with a title from the `./game list` output.

Enjoy!
