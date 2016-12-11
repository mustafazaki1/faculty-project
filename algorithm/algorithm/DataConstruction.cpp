#include "DataConstruction.h"


DataConstruction::DataConstruction()
{
}
vector<string> DataConstruction::Split(string S, char Delimiter) //Splitting a given string by a given delimiter
{
	int Size = S.size();
	string Word;
	vector<string> Words;
	for (int i = 0; i < Size; i++)
	{
		if (S[i] == Delimiter)
		{
			Words.push_back(Word);
			Word = "";
		}
		else
		{
			Word.push_back(S[i]);
		}
	}
	Words.push_back(Word);
	return Words;
}
void DataConstruction::FillMap()				//Construct the two mapping function
{
	string line;
	vector<string>parts;
	vector<string>words;
	ifstream myfile;
	myfile.open("1synsets.txt");	    //Open synsets file
	if (myfile.is_open())			    //Ensure that the file is opened
	{
		while (getline(myfile, line))   //Read line line from the file
		{
			parts = Split(line, ',');   //Split each line comma
			synsetNoun.push_back(parts[1]);   //Push the words in this synset as one stirng


			words = Split(parts[1], ' ');   //Split each string of words by space
			int size = words.size();
			int id;
			stringstream(parts[0]) >> id;	//Convert id from string to int
			for (int i = 0; i < size; i++)	//Map each noun to its synset id
			{
				nounSynset[words[i]].push_back(id);
			}
		}
	}
	myfile.close();						//Close the file
}
void DataConstruction::ConstructGraph()
{
	string line;
	vector<string>hypernyms;
	vector<int>hypernyms1;
	int size, index;
	ifstream myfile;
	myfile.open("2hypernyms.txt");					   //Open synsets file
	if (myfile.is_open())							   //Ensure that the file is opened
	{
		while (getline(myfile, line))				   //Read line line from the file
		{
			hypernyms = Split(line, ',');			   //Split each line comma
			Graph.push_back(hypernyms1);
			size = hypernyms.size();
			for (int i = 1; i < size; i++)
			{
				stringstream(hypernyms[i]) >> index;   //Convert each hypernyms from string to int
				Graph.back().push_back(index);		   //Push each hypernyms as int
			}
		}
	}
	myfile.close();									   //Close the file
}
vector<int> DataConstruction::MapNounToID(string Noun)
{
	return nounSynset[Noun];
}
string DataConstruction::MapIDToNoun(int ID)
{
	return synsetNoun[ID];
}
DataConstruction::~DataConstruction()
{
}