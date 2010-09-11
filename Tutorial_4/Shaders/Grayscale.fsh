//
//  Grayscale.fsh
//  ES2Framework
//
//  Created by Ryan Evans on 9/8/10.
//  All sample code is licensed under the MIT license, enjoy!
//
precision highp float;

varying vec4 colorVarying;

void main()
{
    float gray = colorVarying.x + colorVarying.y + colorVarying.z;
    gray = gray / 3.0;
    gl_FragColor = vec4(gray, gray, gray, 1.0);
}
