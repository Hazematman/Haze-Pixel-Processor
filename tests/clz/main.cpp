#include "Vtop.h"
#include <iostream>
#include <vector>
#include <stdint.h>
using namespace std;


uint16_t count_leading_zeros(uint16_t value)
{
    for(int i = 15; i >= 0; i--)
    {
        if(value & (1 << i))
        {
            return 16 - i - 1;
        }
    }
    return 16;
}


int main(int argc, char *argv[])
{
    Verilated::commandArgs(argc, argv);
    Vtop *top = new Vtop;
    
    vector<uint16_t> test_values;
    test_values.push_back(0x0);
    for(size_t i = 0; i < (1 << 16); i++)
    {
        test_values.push_back(i);
    }
    
    for(size_t i = 0; i < test_values.size(); i++)
    {
        uint16_t test_val =  count_leading_zeros(test_values[i]);
        top->value = test_values[i];
        top->eval();
        if(top->out != test_val)
        {
            cout << "Failed on " << (int)test_values[i] << endl;
            cout << "Got " << top->out << " Expected " << test_val << endl;
            return 1;
        }
    }
    
    cout << "Success!" << endl;
    return 0;
}
