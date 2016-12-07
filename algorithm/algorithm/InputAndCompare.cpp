#include "InputAndCompare.h"



InputAndCompare::InputAndCompare()
{
}

string InputAndCompare::ReadInput()
{
	string testFile;
	cin >> testFile;
	ifstream openFile;
	openFile.open(testFile);
	int counterTest;
	openFile >> counterTest;
	string s;
	for (int i = 0; i <counterTest; i++)
	{
		cin >> s;
		s[1] = 0;
	}
	return "";
}

InputAndCompare::~InputAndCompare()
{
}
