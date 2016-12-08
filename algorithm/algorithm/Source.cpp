#include"WordNetSemantics.h"
using namespace std;


int main()
{
	WordNetSemantics WNS;
	WNS.Run();
	/*SCA temp;
	int counter = 0;
	cin >> counter;
	string s1, s2;
	for (int i = 0; i < counter; i++)
	{
		cin >> s1 >> s2;
		pair<int, vector<string> > answer = temp.SCANouns(s1,s2);
		cout << answer.first << " ------>" << endl;
		for (int i = 0; i < answer.second.size(); i++)
		{
			cout << answer.second[i] << endl;
		}
	}*/
	return 0;
}