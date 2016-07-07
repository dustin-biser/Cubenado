//
//  NormRand.hpp
//

#pragma once


#import <cstdlib>
using std::rand;


inline float rand0to1()
{
    return static_cast<float>(rand()) / RAND_MAX;
}
