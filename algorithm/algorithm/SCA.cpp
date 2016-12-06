#include "SCA.h"


SCA::SCA(int size)
{
	DC.FillMap();
	DC.Construct_graph();
	VisitedNodes.resize(size); // visit
	for (int i = 0; i < size; i++)
	{
		VisitedNodes[i].first = VisitedNodes[i].second = 0;
	}
	curWight.resize(size); // Wight
	for (int i = 0; i < size; i++)
	{
		curWight[i].first = curWight[i].second = 0;
	}
	Counter = 0;
}
pair<int, vector<int> >	SCA::BFS(vector<vector<int> > & Graph, vector<int> FirstGroup, vector<int> SecondGroup)
{
	Counter++;
	pair<int, vector<int> > answer;
	answer.first = 1e9;
		// W , cur node
	queue<BFSData> BFSQueue;
	for (int i = 0; i < FirstGroup.size(); i++)
	{
		BFSData temp;
		temp.curGroup = 0;
		temp.curNode = FirstGroup[i];
		temp.curWight = 0;
		BFSQueue.push(temp);
	}
	for (int i = 0; i < SecondGroup.size(); i++)
	{
		BFSData temp;
		temp.curGroup = 1;
		temp.curNode = SecondGroup[i];
		temp.curWight = 0;
		BFSQueue.push(temp);
	}	
	while (BFSQueue.size())
	{
		int curNode = BFSQueue.front().curNode, W = BFSQueue.front().curWight,curGroup=BFSQueue.front().curGroup;
		BFSQueue.pop();
		//cout << curNode << " " << W << " " << curGroup << endl;
		if ((VisitedNodes[curNode].first!=Counter&&curGroup==0)|| (VisitedNodes[curNode].second!=Counter&&curGroup == 1))
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
					}
				}

			}
		}
	}
	return answer;
}
pair<int, vector<int> > SCA::SCANouns(string FirstNoun, string SecondNoun)
{
	vector<int> FirstGroup = DC.mapNounToID(FirstNoun), SecondGroup = DC.mapNounToID(SecondNoun);
	return BFS(DC.graph, FirstGroup, SecondGroup);
}

SCA::~SCA()
{
}
