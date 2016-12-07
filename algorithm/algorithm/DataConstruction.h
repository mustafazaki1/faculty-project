#pragma once
#include <iostream>
#include <fstream>
#include <string>
#include <stdio.h>
#include <sstream>
#include <vector>
#include <map>
#include <queue>
#include <algorithm>
typedef long long ll;

using namespace std;

class DataConstruction
{
private:
	vector<string> Split(string S, char Delimiter); //Splitting a given string by a given delimiter
	map<string, vector<int> >nounSynset;			//Each word to its synset id
	vector<string>synsetNoun;						//Each synset id has its words

public:
	DataConstruction();
	static vector< vector<int> >Graph;
	void FillMap();						//Construct the two maps
	void ConstructGraph();
	vector<int> MapNounToID(string Noun);
	string MapIDToNoun(int ID);
	~DataConstruction();
};

