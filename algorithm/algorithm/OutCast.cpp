#include "OutCast.h"


OutCast::OutCast()
{
}

string OutCast:: Outcast_relation(SCA & sca, vector<string> nouns)
{

	int size = nouns.size();
	int p, dist;
	string odd;
	vector<int>distance(size);
	distance.assign(size, 0);

	for (int k = 0; k < size; k++)
	{
		for (int j = k+1; j < size; j++)
		{
			p = sca.SCANouns(nouns[j], nouns[k]).first;
			distance[j] += p;
			distance[k] += p;
		}
	}

	    dist = distance[0];
	    odd=nouns[0];
		for (int i = 1; i < size; i++)
		{
			if (distance[i] > dist)
			{
				dist = distance[i];
				odd = nouns[i];
				
			}
			
		}	
	
	return odd;
}

OutCast::~OutCast()
{
}
