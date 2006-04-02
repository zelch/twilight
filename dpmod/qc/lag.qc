
.void(float t, float f1, float f2, entity e1, vector v1, vector v2, vector v3, vector v4) lag_func;

// upto 5 queued messages
.float lag1_time;
.float lag1_float1;
.float lag1_float2;
.entity lag1_entity1;
.vector lag1_vec1;
.vector lag1_vec2;
.vector lag1_vec3;
.vector lag1_vec4;

.float lag2_time;
.float lag2_float1;
.float lag2_float2;
.entity lag2_entity1;
.vector lag2_vec1;
.vector lag2_vec2;
.vector lag2_vec3;
.vector lag2_vec4;

.float lag3_time;
.float lag3_float1;
.float lag3_float2;
.entity lag3_entity1;
.vector lag3_vec1;
.vector lag3_vec2;
.vector lag3_vec3;
.vector lag3_vec4;

.float lag4_time;
.float lag4_float1;
.float lag4_float2;
.entity lag4_entity1;
.vector lag4_vec1;
.vector lag4_vec2;
.vector lag4_vec3;
.vector lag4_vec4;

.float lag5_time;
.float lag5_float1;
.float lag5_float2;
.entity lag5_entity1;
.vector lag5_vec1;
.vector lag5_vec2;
.vector lag5_vec3;
.vector lag5_vec4;

void() lag_update =
{
	if (self.lag1_time) if (time > self.lag1_time) {self.lag_func(self.lag1_time, self.lag1_float1, self.lag1_float2, self.lag1_entity1, self.lag1_vec1, self.lag1_vec2, self.lag1_vec3, self.lag1_vec4);self.lag1_time = 0;}
	if (self.lag2_time) if (time > self.lag2_time) {self.lag_func(self.lag2_time, self.lag2_float1, self.lag2_float2, self.lag2_entity1, self.lag2_vec1, self.lag2_vec2, self.lag2_vec3, self.lag2_vec4);self.lag2_time = 0;}
	if (self.lag3_time) if (time > self.lag3_time) {self.lag_func(self.lag3_time, self.lag3_float1, self.lag3_float2, self.lag3_entity1, self.lag3_vec1, self.lag3_vec2, self.lag3_vec3, self.lag3_vec4);self.lag3_time = 0;}
	if (self.lag4_time) if (time > self.lag4_time) {self.lag_func(self.lag4_time, self.lag4_float1, self.lag4_float2, self.lag4_entity1, self.lag4_vec1, self.lag4_vec2, self.lag4_vec3, self.lag4_vec4);self.lag4_time = 0;}
	if (self.lag5_time) if (time > self.lag5_time) {self.lag_func(self.lag5_time, self.lag5_float1, self.lag5_float2, self.lag5_entity1, self.lag5_vec1, self.lag5_vec2, self.lag5_vec3, self.lag5_vec4);self.lag5_time = 0;}
};

float(float t, float f1, float f2, entity e1, vector v1, vector v2, vector v3, vector v4) lag_additem =
{
	if (self.lag1_time == 0) {self.lag1_time = t;self.lag1_float1 = f1;self.lag1_float2 = f2;self.lag1_entity1 = e1;self.lag1_vec1 = v1;self.lag1_vec2 = v2;self.lag1_vec3 = v3;self.lag1_vec4 = v4;return TRUE;}
	if (self.lag2_time == 0) {self.lag2_time = t;self.lag2_float1 = f1;self.lag2_float2 = f2;self.lag2_entity1 = e1;self.lag2_vec1 = v1;self.lag2_vec2 = v2;self.lag2_vec3 = v3;self.lag2_vec4 = v4;return TRUE;}
	if (self.lag3_time == 0) {self.lag3_time = t;self.lag3_float1 = f1;self.lag3_float2 = f2;self.lag3_entity1 = e1;self.lag3_vec1 = v1;self.lag3_vec2 = v2;self.lag3_vec3 = v3;self.lag3_vec4 = v4;return TRUE;}
	if (self.lag4_time == 0) {self.lag4_time = t;self.lag4_float1 = f1;self.lag4_float2 = f2;self.lag4_entity1 = e1;self.lag4_vec1 = v1;self.lag4_vec2 = v2;self.lag4_vec3 = v3;self.lag4_vec4 = v4;return TRUE;}
	if (self.lag5_time == 0) {self.lag5_time = t;self.lag5_float1 = f1;self.lag5_float2 = f2;self.lag5_entity1 = e1;self.lag5_vec1 = v1;self.lag5_vec2 = v2;self.lag5_vec3 = v3;self.lag5_vec4 = v4;return TRUE;}
	// no room for it (what is the best thing to do here??)
	return FALSE;
};

