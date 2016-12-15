#include "WordNetSemantics.h"


WordNetSemantics::WordNetSemantics()
{
}
void WordNetSemantics::Run()
{
	cout << "WordNet Semantics Project: \n  *Don't forget to include synsets & hypernyms file and input file to project.\n[0] Close Program. \n[1] Semantic Relation Between Pair Of Words.\n[2] Detect Odd Word From A List Of Words.\n\n";
	int Choice;
	SCA temp;
	int counter = 0;
	while (true)
	{
		cout << "Enter your choice[0 - 1 - 2]:";
		cin >> Choice;
		if (Choice == 1)
		{
			ifstream filetestcase;
			ofstream fileout;
			fileout.open("out.txt");
			filetestcase.open("3RelationsQueries.txt");
			filetestcase >> counter;
			string s1, s2;
			filetestcase.ignore();
			for (int i = 0; i < counter; i++)
			{
				getline(filetestcase, s1);
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
				fileout << answer.first << ",";
				for (int i = 0; i < answer.second.size(); i++)
				{
					ss.clear();
					ss << answer.second[i];
					ss >> s1;
					fileout << s1;
					while (ss >> s1)
					{
						fileout << " " << s1;
					}
					if (answer.second.size() != i + 1)
						fileout << " ";
				}
				fileout << endl;
			}
		}
		else if (Choice == 2)
		{
			OutCast outcast;
			ifstream infile("4OutcastQueries.txt");
			ofstream outfile("out2.txt");
			string line, odd;
			getline(infile, line);
			counter = stoi(line);
			while (!infile.eof())
			{
				vector<string>v;
				getline(infile, line);
				for (int i = 0; i < line.size(); i++)
				{
					if (line[i] == ',')
						line[i] = ' ';
				}

				stringstream ss(line);
				string s;
				while (ss >> s)
				{
					v.push_back(s);
				}
				odd = outcast.Outcast_relation(temp, v);

				outfile << odd << endl;
			}
			infile.close();
			outfile.close();
		}
		else
			break;
	}
}
WordNetSemantics::~WordNetSemantics()
{
}
