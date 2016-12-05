#include <iostream>
#include <fstream>
#include <istream>
#include <ostream>
#include <string>
#include <stdio.h>
#include <sstream>
#include <vector>
#include <map>

using namespace std;

class data
{
private:
	vector<string> split(string s, char delimiter) //Splitting a given string by a given delimiter
	{
		int size = s.size();
		string word;
		vector<string> words;
		for (int i = 0; i < size; i++)
		{
			if (s[i] == delimiter)
			{
				words.push_back(word);
				word = "";
			}
			else
			{
				word += s[i];
			}
		}
		words.push_back(word);
		return words;
	}

public:
	vector<string>SynsetNoun;	//map2				//Each synset id has its words
	map<string, int>NounSynset;	//map1		//Each word to its synset id
	vector<vector<int>>graph;
	
	void FillMap ()							//Construct the two mapping function
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
				parts = split(line, ',');   //Split each line comma
				SynsetNoun.push_back(parts[1]);   //Push the words in this synset as one stirng

				words = split(parts[1], ' ');   //Split each string of words by space
				int size = words.size();
				int id;
				stringstream(parts[0]) >> id;	//Convert id from string to int
				for (int i = 0; i < size; i++)	//Map each noun to its synset id
				{
					NounSynset[words[i]] = id;
				}
			}
		}
		myfile.close();						//Close the file
	}

	 void Construct_graph()
	{
		string line;
		vector<string>hypernyms;						   
		vector<int>hypernyms1;							   
		int size, index, c;
		ifstream myfile;
		myfile.open("2hypernyms.txt");					   //Open synsets file
		if (myfile.is_open())							   //Ensure that the file is opened
		{
			while (getline(myfile, line))				   //Read line line from the file
			{
				hypernyms = split(line, ',');			   //Split each line comma

				size = hypernyms.size();
				for (int i = 1; i < size; i++)
				{
					stringstream(hypernyms[i]) >> index;   //Convert each hypernyms from string to int
					hypernyms1.push_back(index);		   //Push each hypernyms as int
				}
				graph.push_back(hypernyms1);
				hypernyms1.clear();
			}
		}
		myfile.close();									   //Close the file
	}

};


int main()
{
	data d;
	d.FillMap();
	d.Construct_graph();
	cout << "//////" << endl;
	return 0;
}