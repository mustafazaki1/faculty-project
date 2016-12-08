#pragma once
#include "DataConstruction.h"

class SCA
{
private:
	vector<pair<int,int> > VisitedNodes;
	vector< pair<int,int> > curWight;
	int Counter;
	struct BFSData
	{
		int curWight;
		int curNode;
		int curGroup;
	};

public:
	DataConstruction DC;
	SCA();
	pair<int, vector<int> > BFS(vector<vector<int> > & Graph, vector<int> FirstGroup, vector<int> SecondGroup);
	pair<int, vector<string> > SCANouns(string FirstNoun, string SecondNoun);
	~SCA();
};

