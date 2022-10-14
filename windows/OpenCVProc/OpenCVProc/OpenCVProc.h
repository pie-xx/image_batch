#pragma once
// 以下の ifdef ブロックは、DLL からのエクスポートを容易にするマクロを作成するための
// 一般的な方法です。この DLL 内のすべてのファイルは、コマンド ラインで定義された FILTERDLL1_EXPORTS
// シンボルを使用してコンパイルされます。このシンボルは、この DLL を使用するプロジェクトでは定義できません。
// ソースファイルがこのファイルを含んでいる他のプロジェクトは、
// FILTERDLL1_API 関数を DLL からインポートされたと見なすのに対し、この DLL は、このマクロで定義された
// シンボルをエクスポートされたと見なします。
#ifdef FILTERDLL1_EXPORTS
#define FILTERDLL1_API __declspec(dllexport)
#else
#define FILTERDLL1_API __declspec(dllimport)
#endif
extern "C"  __declspec(dllexport)
void RotImg(char* inpath, char* outpath, int* ipara, int* outpara);
