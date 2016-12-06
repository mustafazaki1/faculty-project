#pragma once
#include <iostream>
#include <fstream>
#include <string>
#include <stdio.h>
#include <sstream>
#include <vector>
#include <map>
#include <queue>
typedef long long ll;
using namespace std;
class DataConstruction
{
private:
	vector<string> split(string s, char delimiter); //Splitting a given string by a given delimiter
public:
	map<string, vector<int> >NounSynset;			//Each word to its synset id
	vector<string>SynsetNoun;			//Each synset id has its words
	vector< vector<int> >graph;
	DataConstruction();
	void FillMap();						//Construct the two mapping function
	void Construct_graph();
	vector<int> mapNounToID(string Noun);
	string mapIDToNoun(int ID);
	~DataConstruction();
};

