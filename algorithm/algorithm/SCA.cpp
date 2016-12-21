#include "SCA.h"
#include <time.h>      
#include <math.h>

SCA::SCA()
{
	clock_t b;
	b = clock();
	DC.FillMap();
	DC.ConstructGraph();
	b = clock() - b;
	cout << ((float)b) / CLOCKS_PER_SEC << endl;
	int size = DC.Graph.size();
	VisitedNodes.resize(size);


	for (int i = 0; i < size; i++) 					// initialize visited array 
	{
		VisitedNodes[i].first = VisitedNodes[i].second = 0;
	}
	curWight.resize(size);
	for (int i = 0; i < size; i++)
	{
		curWight[i].first = curWight[i].second = 0;
	}
	Counter = 0;
}


pair<int, vector<int> >	SCA::BFS(vector<vector<int> > & Graph, vector<int> FirstGroup, vector<int> SecondGroup)
{
	Counter++;                                       // Number of entrance time in this function and using it for checking if visit or not
	pair<int, vector<int> > answer;
	answer.first = 1e9;
	queue<BFSData> BFSQueue;
	for (int i = 0; i < FirstGroup.size(); i++) 	//Push nodes contain first word to Queue
	{
		BFSData temp;
		temp.curGroup = 0;
		temp.curNode = FirstGroup[i];
		temp.curWight = 0;
		BFSQueue.push(temp);
	}
	for (int i = 0; i < SecondGroup.size(); i++) 	//Push nodes contain second word to Queue
	{
		BFSData temp;
		temp.curGroup = 1;
		temp.curNode = SecondGroup[i];
		temp.curWight = 0;
		BFSQueue.push(temp);
	}
	while (BFSQueue.size())
	{
		int curNode = BFSQueue.front().curNode, W = BFSQueue.front().curWight, curGroup = BFSQueue.front().curGroup;
		BFSQueue.pop();
		if ((VisitedNodes[curNode].first != Counter&&curGroup == 0) || (VisitedNodes[curNode].second != Counter&&curGroup == 1)) 	//Check if the current Node visited by the groups or not
		{
			if (curGroup == 0)
			{
				VisitedNodes[curNode].first = Counter;
				curWight[curNode].first = W;
				if (VisitedNodes[curNode].second == Counter&&W + curWight[curNode].second <= answer.first)
				{
					if (W + curWight[curNode].second == answer.first)
					{
						answer.second.push_back(curNode);
					}
					else
					{
						answer.first = W + curWight[curNode].second;
						answer.second.clear();
						answer.second.push_back(curNode);
					}
				}
				for (int i = 0; i < Graph[curNode].size(); i++)
				{
					if (VisitedNodes[Graph[curNode][i]].first != Counter)
					{
						BFSData temp;
						temp.curGroup = curGroup;
						temp.curWight = W + 1;
						temp.curNode = Graph[curNode][i];
						if (temp.curWight <= answer.first)
							BFSQueue.push(temp);
						else break;
					}
				}
			}
			else
			{
				VisitedNodes[curNode].second = Counter;
				curWight[curNode].second = W;
				if (VisitedNodes[curNode].first == Counter&&W + curWight[curNode].first <= answer.first)
				{
					if (W + curWight[curNode].first == answer.first)
					{
						answer.second.push_back(curNode);
					}
					else
					{
						answer.first = W + curWight[curNode].first;
						answer.second.clear();
						answer.second.push_back(curNode);
					}
				}
				for (int i = 0; i < Graph[curNode].size(); i++)
				{
					if (VisitedNodes[Graph[curNode][i]].second != Counter)
					{
						BFSData temp;
						temp.curGroup = curGroup;
						temp.curWight = W + 1;
						temp.curNode = Graph[curNode][i];
						if (temp.curWight <= answer.first)
							BFSQueue.push(temp);
						else break;
					}
				}


			}
		}
	}
	return answer;
}
pair<int, vector<string> > SCA::SCANouns(string FirstNoun, string SecondNoun)
{
	pair<int, vector<int> > Result = BFS(DC.Graph, DC.MapNounToID(FirstNoun), DC.MapNounToID(SecondNoun));
	pair <int, vector<string>> NounsResult;
	NounsResult.first = Result.first;
	for (int i = 0; i < Result.second.size(); i++)
	{
		NounsResult.second.push_back(DC.MapIDToNoun(Result.second[i]));
	}
	return NounsResult;
}
SCA::~SCA()
{
}




