#include "WordNetSemantics.h"


WordNetSemantics::WordNetSemantics()
{
}
void WordNetSemantics::Run()
{
	cout << "WordNet Semantics Project: \n  *Don't forget to include synsets & hypernyms file and input file to project.\n[1] Semantic Relation Between Pair Of Words.\n[2] Detect Odd Word From A List Of Words.\nEnter your choice [1-2]: ";
	int Choice;
	cin >> Choice;
	if (Choice == 1)
	{
		SCA temp;
		ifstream filetestcase;
		ofstream fileout;
		fileout.open("out.txt");
		filetestcase.open("3RelationsQueries.txt");
		int counter = 0;
		filetestcase>> counter;
		string s1, s2;
		for (int i = 0; i < counter; i++)
		{
			filetestcase >> s1;
			stringstream ss;
			for (int h = 0; h < s1.size(); h++)
			{
				if (s1[h] == ',')
				{
					s1[h] = ' ';
					break;
				}
			}
			ss << s1;
			ss >> s1;
			ss >> s2;
			pair<int, vector<string> > answer = temp.SCANouns(s1, s2);
			fileout << s1 << "," << s2 << "		dist=" << answer.first << "	sca=";
			for (int i = 0; i < answer.second.size(); i++)
			{
				if (i != answer.second.size() - 1)
					fileout << answer.second[i] << " OR ";
				else
					fileout << answer.second[i] << endl;
			}
		}
	}
	else
	{
		cout << "lsa m4 5lsan" << endl;
	}
}
WordNetSemantics::~WordNetSemantics()
{
}
