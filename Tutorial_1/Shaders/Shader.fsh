//
//  Shader.fsh
//  ES2Framework
//
//  Created by Ryan Evans on 9/4/10.
//  All sample code is licensed under the MIT license, enjoy!
//
precision mediump float;

varying vec4 colorVarying;

void main()
{
    vec4 newcolor = colorVarying;
    newcolor.rg = newcolor.gr;
    gl_FragColor = newcolor;
}
