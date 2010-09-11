//
//  Shader.fsh
//  ES2Framework
//
//  Created by Ryan Evans on 9/4/10.
//  All sample code is licensed under the MIT license, enjoy!
//
precision highp float;

varying vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
