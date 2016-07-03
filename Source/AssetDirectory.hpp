//
//  AssetDirectory.h
//

#pragma once

#include <unordered_map>

typedef std::string FileName;
typedef std::string PathToFile;
typedef std::unordered_map<FileName, PathToFile> AssetDirectory;
