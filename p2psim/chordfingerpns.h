#ifndef __CHORDFINGERPNS_H
#define __CHORDFINGERPNS_H

#include "chord.h"
#include <stdio.h>

/* ChordFingerPNS does Gummadi^2's PNS proximity routing, it's completely static now*/

class LocTablePNS : public LocTable {
  public:
    LocTablePNS() : LocTable() {
      fingers.clear();
    };
    ~LocTablePNS() {};

    Chord::IDMap next_hop(Chord::CHID key, bool *done) {
      //check if one of my finger is directly responsible for it
      for (uint i = 0; i < fingers.size(); i++){
	if (ConsistentHash::betweenrightincl(fingers[i].first.id, fingers[i].second.id, key)){
//	  return fingers[i].second;
	  *done = true;
	  return fingers[i].second;
	}
      }
      return LocTable::next_hop(key, done);
    };

    void add_finger(pair<Chord::IDMap, Chord::IDMap> finger) {
      fingers.push_back(finger);
    };

    vector<pair<Chord::IDMap, Chord::IDMap> > fingers;
};

class ChordFingerPNS: public Chord {
  public:
    ChordFingerPNS(Node *n, Args a);
    ~ChordFingerPNS() {};
    string proto_name() { return "ChordFingerPNS"; }

    bool stabilized(vector<CHID> lid);
    void dump();
    void init_state(vector<IDMap> ids);

  protected:
    uint _base;
    int _samples;
};

#endif
