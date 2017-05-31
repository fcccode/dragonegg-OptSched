// RUN: %clang_cc1 -triple x86_64-apple-darwin -emit-llvm %s -o - 2>&1 | FileCheck %s

#define strcpy(dest, src) \
  ((__builtin_object_size(dest, 0) != -1ULL) \
   ? __builtin___strcpy_chk (dest, src, __builtin_object_size(dest, 1)) \
   : __inline_strcpy_chk(dest, src))

static char *__inline_strcpy_chk (char *dest, const char *src) {
  return __builtin___strcpy_chk(dest, src, __builtin_object_size(dest, 1));
}

char gbuf[63];
char *gp;
int gi, gj;

// CHECK-LABEL: define void @test1
void test1() {
  // CHECK:     = call i8* @__strcpy_chk(i8* getelementptr inbounds ([63 x i8], [63 x i8]* @gbuf, i64 0, i64 4), i8* getelementptr inbounds ([9 x i8], [9 x i8]* @.str, i32 0, i32 0), i64 59)
  strcpy(&gbuf[4], "Hi there");
}

// CHECK-LABEL: define void @test2
void test2() {
  // CHECK:     = call i8* @__strcpy_chk(i8* getelementptr inbounds ([63 x i8], [63 x i8]* @gbuf, i32 0, i32 0), i8* getelementptr inbounds ([9 x i8], [9 x i8]* @.str, i32 0, i32 0), i64 63)
  strcpy(gbuf, "Hi there");
}

// CHECK-LABEL: define void @test3
void test3() {
  // CHECK:     = call i8* @__strcpy_chk(i8* getelementptr inbounds ([63 x i8], [63 x i8]* @gbuf, i64 1, i64 37), i8* getelementptr inbounds ([9 x i8], [9 x i8]* @.str, i32 0, i32 0), i64 0)
  strcpy(&gbuf[100], "Hi there");
}

// CHECK-LABEL: define void @test4
void test4() {
  // CHECK:     = call i8* @__strcpy_chk(i8* getelementptr inbounds ([63 x i8], [63 x i8]* @gbuf, i64 0, i64 -1), i8* getelementptr inbounds ([9 x i8], [9 x i8]* @.str, i32 0, i32 0), i64 0)
  strcpy((char*)(void*)&gbuf[-1], "Hi there");
}

// CHECK-LABEL: define void @test5
void test5() {
  // CHECK:     = load i8*, i8** @gp
  // CHECK-NEXT:= call i64 @llvm.objectsize.i64.p0i8(i8* %{{.*}}, i1 false)
  strcpy(gp, "Hi there");
}

// CHECK-LABEL: define void @test6
void test6() {
  char buf[57];

  // CHECK:       = call i8* @__strcpy_chk(i8* %{{.*}}, i8* getelementptr inbounds ([9 x i8], [9 x i8]* @.str, i32 0, i32 0), i64 53)
  strcpy(&buf[4], "Hi there");
}

// CHECK-LABEL: define void @test7
void test7() {
  int i;
  // Ensure we only evaluate the side-effect once.
  // CHECK:     = add
  // CHECK-NOT: = add
  // CHECK:     = call i8* @__strcpy_chk(i8* getelementptr inbounds ([63 x i8], [63 x i8]* @gbuf, i32 0, i32 0), i8* getelementptr inbounds ([9 x i8], [9 x i8]* @.str, i32 0, i32 0), i64 63)
  strcpy((++i, gbuf), "Hi there");
}

// CHECK-LABEL: define void @test8
void test8() {
  char *buf[50];
  // CHECK-NOT:   __strcpy_chk
  // CHECK:       = call i8* @__inline_strcpy_chk(i8* %{{.*}}, i8* getelementptr inbounds ([9 x i8], [9 x i8]* @.str, i32 0, i32 0))
  strcpy(buf[++gi], "Hi there");
}

// CHECK-LABEL: define void @test9
void test9() {
  // CHECK-NOT:   __strcpy_chk
  // CHECK:       = call i8* @__inline_strcpy_chk(i8* %{{.*}}, i8* getelementptr inbounds ([9 x i8], [9 x i8]* @.str, i32 0, i32 0))
  strcpy((char *)((++gi) + gj), "Hi there");
}

// CHECK-LABEL: define void @test10
char **p;
void test10() {
  // CHECK-NOT:   __strcpy_chk
  // CHECK:       = call i8* @__inline_strcpy_chk(i8* %{{.*}}, i8* getelementptr inbounds ([9 x i8], [9 x i8]* @.str, i32 0, i32 0))
  strcpy(*(++p), "Hi there");
}

// CHECK-LABEL: define void @test11
void test11() {
  // CHECK-NOT:   __strcpy_chk
  // CHECK:       = call i8* @__inline_strcpy_chk(i8* getelementptr inbounds ([63 x i8], [63 x i8]* @gbuf, i32 0, i32 0), i8* getelementptr inbounds ([9 x i8], [9 x i8]* @.str, i32 0, i32 0))
  strcpy(gp = gbuf, "Hi there");
}

// CHECK-LABEL: define void @test12
void test12() {
  // CHECK-NOT:   __strcpy_chk
  // CHECK:       = call i8* @__inline_strcpy_chk(i8* %{{.*}}, i8* getelementptr inbounds ([9 x i8], [9 x i8]* @.str, i32 0, i32 0))
  strcpy(++gp, "Hi there");
}

// CHECK-LABEL: define void @test13
void test13() {
  // CHECK-NOT:   __strcpy_chk
  // CHECK:       = call i8* @__inline_strcpy_chk(i8* %{{.*}}, i8* getelementptr inbounds ([9 x i8], [9 x i8]* @.str, i32 0, i32 0))
  strcpy(gp++, "Hi there");
}

// CHECK-LABEL: define void @test14
void test14() {
  // CHECK-NOT:   __strcpy_chk
  // CHECK:       = call i8* @__inline_strcpy_chk(i8* %{{.*}}, i8* getelementptr inbounds ([9 x i8], [9 x i8]* @.str, i32 0, i32 0))
  strcpy(--gp, "Hi there");
}

// CHECK-LABEL: define void @test15
void test15() {
  // CHECK-NOT:   __strcpy_chk
  // CHECK:       = call i8* @__inline_strcpy_chk(i8* %{{..*}}, i8* getelementptr inbounds ([9 x i8], [9 x i8]* @.str, i32 0, i32 0))
  strcpy(gp--, "Hi there");
}

// CHECK-LABEL: define void @test16
void test16() {
  // CHECK-NOT:   __strcpy_chk
  // CHECK:       = call i8* @__inline_strcpy_chk(i8* %{{.*}}, i8* getelementptr inbounds ([9 x i8], [9 x i8]* @.str, i32 0, i32 0))
  strcpy(gp += 1, "Hi there");
}

// CHECK-LABEL: @test17
void test17() {
  // CHECK: store i32 -1
  gi = __builtin_object_size(gp++, 0);
  // CHECK: store i32 -1
  gi = __builtin_object_size(gp++, 1);
  // CHECK: store i32 0
  gi = __builtin_object_size(gp++, 2);
  // CHECK: store i32 0
  gi = __builtin_object_size(gp++, 3);
}

// CHECK-LABEL: @test18
unsigned test18(int cond) {
  int a[4], b[4];
  // CHECK: phi i32*
  // CHECK: call i64 @llvm.objectsize.i64
  return __builtin_object_size(cond ? a : b, 0);
}

// CHECK-LABEL: @test19
void test19() {
  struct {
    int a, b;
  } foo;

  // CHECK: store i32 8
  gi = __builtin_object_size(&foo.a, 0);
  // CHECK: store i32 4
  gi = __builtin_object_size(&foo.a, 1);
  // CHECK: store i32 8
  gi = __builtin_object_size(&foo.a, 2);
  // CHECK: store i32 4
  gi = __builtin_object_size(&foo.a, 3);

  // CHECK: store i32 4
  gi = __builtin_object_size(&foo.b, 0);
  // CHECK: store i32 4
  gi = __builtin_object_size(&foo.b, 1);
  // CHECK: store i32 4
  gi = __builtin_object_size(&foo.b, 2);
  // CHECK: store i32 4
  gi = __builtin_object_size(&foo.b, 3);
}

// CHECK-LABEL: @test20
void test20() {
  struct { int t[10]; } t[10];

  // CHECK: store i32 380
  gi = __builtin_object_size(&t[0].t[5], 0);
  // CHECK: store i32 20
  gi = __builtin_object_size(&t[0].t[5], 1);
  // CHECK: store i32 380
  gi = __builtin_object_size(&t[0].t[5], 2);
  // CHECK: store i32 20
  gi = __builtin_object_size(&t[0].t[5], 3);
}

// CHECK-LABEL: @test21
void test21() {
  struct { int t; } t;

  // CHECK: store i32 0
  gi = __builtin_object_size(&t + 1, 0);
  // CHECK: store i32 0
  gi = __builtin_object_size(&t + 1, 1);
  // CHECK: store i32 0
  gi = __builtin_object_size(&t + 1, 2);
  // CHECK: store i32 0
  gi = __builtin_object_size(&t + 1, 3);

  // CHECK: store i32 0
  gi = __builtin_object_size(&t.t + 1, 0);
  // CHECK: store i32 0
  gi = __builtin_object_size(&t.t + 1, 1);
  // CHECK: store i32 0
  gi = __builtin_object_size(&t.t + 1, 2);
  // CHECK: store i32 0
  gi = __builtin_object_size(&t.t + 1, 3);
}

// CHECK-LABEL: @test22
void test22() {
  struct { int t[10]; } t[10];

  // CHECK: store i32 0
  gi = __builtin_object_size(&t[10], 0);
  // CHECK: store i32 0
  gi = __builtin_object_size(&t[10], 1);
  // CHECK: store i32 0
  gi = __builtin_object_size(&t[10], 2);
  // CHECK: store i32 0
  gi = __builtin_object_size(&t[10], 3);

  // CHECK: store i32 0
  gi = __builtin_object_size(&t[9].t[10], 0);
  // CHECK: store i32 0
  gi = __builtin_object_size(&t[9].t[10], 1);
  // CHECK: store i32 0
  gi = __builtin_object_size(&t[9].t[10], 2);
  // CHECK: store i32 0
  gi = __builtin_object_size(&t[9].t[10], 3);

  // CHECK: store i32 0
  gi = __builtin_object_size((char*)&t[0] + sizeof(t), 0);
  // CHECK: store i32 0
  gi = __builtin_object_size((char*)&t[0] + sizeof(t), 1);
  // CHECK: store i32 0
  gi = __builtin_object_size((char*)&t[0] + sizeof(t), 2);
  // CHECK: store i32 0
  gi = __builtin_object_size((char*)&t[0] + sizeof(t), 3);

  // CHECK: store i32 0
  gi = __builtin_object_size((char*)&t[9].t[0] + 10*sizeof(t[0].t), 0);
  // CHECK: store i32 0
  gi = __builtin_object_size((char*)&t[9].t[0] + 10*sizeof(t[0].t), 1);
  // CHECK: store i32 0
  gi = __builtin_object_size((char*)&t[9].t[0] + 10*sizeof(t[0].t), 2);
  // CHECK: store i32 0
  gi = __builtin_object_size((char*)&t[9].t[0] + 10*sizeof(t[0].t), 3);
}

struct Test23Ty { int a; int t[10]; };

// CHECK-LABEL: @test23
void test23(struct Test23Ty *p) {
  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* %{{.*}}, i1 false)
  gi = __builtin_object_size(p, 0);
  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* %{{.*}}, i1 false)
  gi = __builtin_object_size(p, 1);
  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* %{{.*}}, i1 true)
  gi = __builtin_object_size(p, 2);
  // Note: this is currently fixed at 0 because LLVM doesn't have sufficient
  // data to correctly handle type=3
  // CHECK: store i32 0
  gi = __builtin_object_size(p, 3);

  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* %{{.*}}, i1 false)
  gi = __builtin_object_size(&p->a, 0);
  // CHECK: store i32 4
  gi = __builtin_object_size(&p->a, 1);
  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* %{{.*}}, i1 true)
  gi = __builtin_object_size(&p->a, 2);
  // CHECK: store i32 4
  gi = __builtin_object_size(&p->a, 3);

  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* %{{.*}}, i1 false)
  gi = __builtin_object_size(&p->t[5], 0);
  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* %{{.*}}, i1 false)
  gi = __builtin_object_size(&p->t[5], 1);
  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* %{{.*}}, i1 true)
  gi = __builtin_object_size(&p->t[5], 2);
  // CHECK: store i32 20
  gi = __builtin_object_size(&p->t[5], 3);
}

// PR24493 -- ICE if __builtin_object_size called with NULL and (Type & 1) != 0
// CHECK-LABEL: @test24
void test24() {
  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* {{.*}}, i1 false)
  gi = __builtin_object_size((void*)0, 0);
  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* {{.*}}, i1 false)
  gi = __builtin_object_size((void*)0, 1);
  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* {{.*}}, i1 true)
  gi = __builtin_object_size((void*)0, 2);
  // Note: Currently fixed at zero because LLVM can't handle type=3 correctly.
  // Hopefully will be lowered properly in the future.
  // CHECK: store i32 0
  gi = __builtin_object_size((void*)0, 3);
}

// CHECK-LABEL: @test25
void test25() {
  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* {{.*}}, i1 false)
  gi = __builtin_object_size((void*)0x1000, 0);
  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* {{.*}}, i1 false)
  gi = __builtin_object_size((void*)0x1000, 1);
  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* {{.*}}, i1 true)
  gi = __builtin_object_size((void*)0x1000, 2);
  // Note: Currently fixed at zero because LLVM can't handle type=3 correctly.
  // Hopefully will be lowered properly in the future.
  // CHECK: store i32 0
  gi = __builtin_object_size((void*)0x1000, 3);

  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* {{.*}}, i1 false)
  gi = __builtin_object_size((void*)0 + 0x1000, 0);
  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* {{.*}}, i1 false)
  gi = __builtin_object_size((void*)0 + 0x1000, 1);
  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* {{.*}}, i1 true)
  gi = __builtin_object_size((void*)0 + 0x1000, 2);
  // Note: Currently fixed at zero because LLVM can't handle type=3 correctly.
  // Hopefully will be lowered properly in the future.
  // CHECK: store i32 0
  gi = __builtin_object_size((void*)0 + 0x1000, 3);
}

// CHECK-LABEL: @test26
void test26() {
  struct { int v[10]; } t[10];

  // CHECK: store i32 316
  gi = __builtin_object_size(&t[1].v[11], 0);
  // CHECK: store i32 312
  gi = __builtin_object_size(&t[1].v[12], 1);
  // CHECK: store i32 308
  gi = __builtin_object_size(&t[1].v[13], 2);
  // CHECK: store i32 0
  gi = __builtin_object_size(&t[1].v[14], 3);
}

struct Test27IncompleteTy;

// CHECK-LABEL: @test27
void test27(struct Test27IncompleteTy *t) {
  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* %{{.*}}, i1 false)
  gi = __builtin_object_size(t, 0);
  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* %{{.*}}, i1 false)
  gi = __builtin_object_size(t, 1);
  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* %{{.*}}, i1 true)
  gi = __builtin_object_size(t, 2);
  // Note: this is currently fixed at 0 because LLVM doesn't have sufficient
  // data to correctly handle type=3
  // CHECK: store i32 0
  gi = __builtin_object_size(t, 3);

  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* {{.*}}, i1 false)
  gi = __builtin_object_size(&test27, 0);
  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* {{.*}}, i1 false)
  gi = __builtin_object_size(&test27, 1);
  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* {{.*}}, i1 true)
  gi = __builtin_object_size(&test27, 2);
  // Note: this is currently fixed at 0 because LLVM doesn't have sufficient
  // data to correctly handle type=3
  // CHECK: store i32 0
  gi = __builtin_object_size(&test27, 3);
}

// The intent of this test is to ensure that __builtin_object_size treats `&foo`
// and `(T*)&foo` identically, when used as the pointer argument.
// CHECK-LABEL: @test28
void test28() {
  struct { int v[10]; } t[10];

#define addCasts(s) ((char*)((short*)(s)))
  // CHECK: store i32 360
  gi = __builtin_object_size(addCasts(&t[1]), 0);
  // CHECK: store i32 360
  gi = __builtin_object_size(addCasts(&t[1]), 1);
  // CHECK: store i32 360
  gi = __builtin_object_size(addCasts(&t[1]), 2);
  // CHECK: store i32 360
  gi = __builtin_object_size(addCasts(&t[1]), 3);

  // CHECK: store i32 356
  gi = __builtin_object_size(addCasts(&t[1].v[1]), 0);
  // CHECK: store i32 36
  gi = __builtin_object_size(addCasts(&t[1].v[1]), 1);
  // CHECK: store i32 356
  gi = __builtin_object_size(addCasts(&t[1].v[1]), 2);
  // CHECK: store i32 36
  gi = __builtin_object_size(addCasts(&t[1].v[1]), 3);
#undef addCasts
}

struct DynStructVar {
  char fst[16];
  char snd[];
};

struct DynStruct0 {
  char fst[16];
  char snd[0];
};

struct DynStruct1 {
  char fst[16];
  char snd[1];
};

struct StaticStruct {
  char fst[16];
  char snd[2];
};

// CHECK-LABEL: @test29
void test29(struct DynStructVar *dv, struct DynStruct0 *d0,
            struct DynStruct1 *d1, struct StaticStruct *ss) {
  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* %{{.*}}, i1 false)
  gi = __builtin_object_size(dv->snd, 0);
  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* %{{.*}}, i1 false)
  gi = __builtin_object_size(dv->snd, 1);
  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* %{{.*}}, i1 true)
  gi = __builtin_object_size(dv->snd, 2);
  // CHECK: store i32 0
  gi = __builtin_object_size(dv->snd, 3);

  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* %{{.*}}, i1 false)
  gi = __builtin_object_size(d0->snd, 0);
  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* %{{.*}}, i1 false)
  gi = __builtin_object_size(d0->snd, 1);
  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* %{{.*}}, i1 true)
  gi = __builtin_object_size(d0->snd, 2);
  // CHECK: store i32 0
  gi = __builtin_object_size(d0->snd, 3);

  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* %{{.*}}, i1 false)
  gi = __builtin_object_size(d1->snd, 0);
  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* %{{.*}}, i1 false)
  gi = __builtin_object_size(d1->snd, 1);
  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* %{{.*}}, i1 true)
  gi = __builtin_object_size(d1->snd, 2);
  // CHECK: store i32 1
  gi = __builtin_object_size(d1->snd, 3);

  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* %{{.*}}, i1 false)
  gi = __builtin_object_size(ss->snd, 0);
  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* %{{.*}}, i1 false)
  gi = __builtin_object_size(ss->snd, 1);
  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* %{{.*}}, i1 true)
  gi = __builtin_object_size(ss->snd, 2);
  // CHECK: store i32 2
  gi = __builtin_object_size(ss->snd, 3);
}

// CHECK-LABEL: @test30
void test30() {
  struct { struct DynStruct1 fst, snd; } *nested;

  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* %{{.*}}, i1 false)
  gi = __builtin_object_size(nested->fst.snd, 0);
  // CHECK: store i32 1
  gi = __builtin_object_size(nested->fst.snd, 1);
  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* %{{.*}}, i1 true)
  gi = __builtin_object_size(nested->fst.snd, 2);
  // CHECK: store i32 1
  gi = __builtin_object_size(nested->fst.snd, 3);

  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* %{{.*}}, i1 false)
  gi = __builtin_object_size(nested->snd.snd, 0);
  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* %{{.*}}, i1 false)
  gi = __builtin_object_size(nested->snd.snd, 1);
  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* %{{.*}}, i1 true)
  gi = __builtin_object_size(nested->snd.snd, 2);
  // CHECK: store i32 1
  gi = __builtin_object_size(nested->snd.snd, 3);

  union { struct DynStruct1 d1; char c[1]; } *u;
  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* %{{.*}}, i1 false)
  gi = __builtin_object_size(u->c, 0);
  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* %{{.*}}, i1 false)
  gi = __builtin_object_size(u->c, 1);
  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* %{{.*}}, i1 true)
  gi = __builtin_object_size(u->c, 2);
  // CHECK: store i32 1
  gi = __builtin_object_size(u->c, 3);

  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* %{{.*}}, i1 false)
  gi = __builtin_object_size(u->d1.snd, 0);
  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* %{{.*}}, i1 false)
  gi = __builtin_object_size(u->d1.snd, 1);
  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* %{{.*}}, i1 true)
  gi = __builtin_object_size(u->d1.snd, 2);
  // CHECK: store i32 1
  gi = __builtin_object_size(u->d1.snd, 3);
}

// CHECK-LABEL: @test31
void test31() {
  // Miscellaneous 'writing off the end' detection tests
  struct DynStructVar *dsv;
  struct DynStruct0 *ds0;
  struct DynStruct1 *ds1;
  struct StaticStruct *ss;

  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* %{{.*}}, i1 false)
  gi = __builtin_object_size(ds1[9].snd, 1);

  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* %{{.*}}, i1 false)
  gi = __builtin_object_size(&ss[9].snd[0], 1);

  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* %{{.*}}, i1 false)
  gi = __builtin_object_size(&ds1[9].snd[0], 1);

  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* %{{.*}}, i1 false)
  gi = __builtin_object_size(&ds0[9].snd[0], 1);

  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* %{{.*}}, i1 false)
  gi = __builtin_object_size(&dsv[9].snd[0], 1);
}

// CHECK-LABEL: @PR30346
void PR30346() {
  struct sa_family_t {};
  struct sockaddr {
    struct sa_family_t sa_family;
    char sa_data[14];
  };

  struct sockaddr *sa;
  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* %{{.*}}, i1 false)
  gi = __builtin_object_size(sa->sa_data, 0);
  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* %{{.*}}, i1 false)
  gi = __builtin_object_size(sa->sa_data, 1);
  // CHECK: call i64 @llvm.objectsize.i64.p0i8(i8* %{{.*}}, i1 true)
  gi = __builtin_object_size(sa->sa_data, 2);
  // CHECK: store i32 14
  gi = __builtin_object_size(sa->sa_data, 3);
}