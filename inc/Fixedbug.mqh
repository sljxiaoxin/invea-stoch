//+------------------------------------------------------------------+
//|                                                  CTradeMgr.mqh |
//|                                 Copyright 2015, Vasiliy Sokolov. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015."
#property link      "http://www.mql5.com"

/*
'm_array' - structures containing objects are not allowed	dictionary.mqh	304	25
for bug https://www.mql5.com/en/forum/192194/page4
https://www.mql5.com/en/forum/192194/page5
*/
template <typename T> 
int ArrayCopy( T &destination[],  T &source[], const int dstStartIndex = 0, const int srcStartIndex = 0, const int count = WHOLE_ARRAY ){
  const int srcSize = ArraySize(source);
  const int endCopyIndex = (count==WHOLE_ARRAY) ? ArraySize(source) : count;

  
  ArrayResize(destination, (int)MathAbs(endCopyIndex-srcStartIndex) );
  
  int copied=0;
  for(int i=srcStartIndex; (i<srcSize)&&(i<endCopyIndex); i++ ){
    destination[dstStartIndex+i] = source[i];  
    copied++;
  }
  
  return copied;
}

template <typename T>
class CASTING
{
public:
  template <typename T1>
  static const T Casting( const T1 &Value )
  {
    union CAST
    {
      T1 Value1;
      const T Value2;

      CAST( const T1 &Value)
      {
        this.Value1 = Value; // кастомный оператор может все испортить
      }
    };

    const CAST Union(Value);

    return(Union.Value2);
  }
};
#define _C(A, B) CASTING<A>::Casting(B)